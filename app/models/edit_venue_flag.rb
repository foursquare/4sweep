class EditVenueFlag < Flag
  serialize :edits, JSON

  attr_accessible :edits

  validates_presence_of :edits, :on => :create, :message => "can't be blank"

  def self.streetCleanup(text)
    # This is just some normalization Foursquare does to
    # addresses. This logic is brittle and non-i18n'ed,
    # needs more data to derive proper rules.
    text.gsub!(/\./,'')
    text.gsub!("Street", "St")
    text.gsub!("Road", "Rd")
    text.gsub!("Avenue", "Ave")
    text.gsub!("Boulevard", "Blvd")
    text.gsub!("Turnpike", "Tpke")
    text.gsub!("Circle", "Cir")
    text.gsub!("Drive", "Dr")
    text.gsub!("Lane", "Ln")
    text.gsub!("Court", "Ct")
    text.gsub!("Mount", "Mt")
    text.gsub!("Route", "Rte")
    text.gsub!("Heights", "Hts")
    text.gsub!(/[;,] *Suite *#/, " #")
    text.gsub!(/[;,] *Suite/, " Ste")
    text.gsub!(/[;,] *Ste/, " Ste")
    text.gsub!(/[;,] *#/, ' #')
    text.gsub!(/ (#|Suite|Ste)/, "\\1")
    return text
  end

  DAYS = {
    1 => "Mon",
    2 => "Tue",
    3 => "Wed",
    4 => "Thu",
    5 => "Fri",
    6 => "Sat",
    7 => "Sun"
  }


  KNOWN_FIELDS = {
    "name" => {
      :friendly_name => "Name",
      :value_getter => lambda {|v,h| [v.name || ""]},
      :normalizer => lambda {|t| t.strip}
    },
    "address" => {
      :friendly_name => "Address",
      :value_getter => lambda {|v,h| [v.location.address || ""]},
      :normalizer => lambda {|t| self.streetCleanup(t).strip}
    },
    "crossStreet" => {
      :friendly_name => "Cross Street",
      :value_getter => lambda {|v,h| [v.location.crossStreet || ""]},
      :normalizer => lambda {|t| self.streetCleanup(t).strip}
    },
    "neighborhood" => {
      :friendly_name => "neighborhood",
      :value_getter => lambda {|v,h| [v.location.neighborhood || ""]},
      :normalizer => lambda {|t| t.strip}
    },
    "city" => {
      :friendly_name => "City",
      :value_getter => lambda {|v,h| [v.location.city || ""]},
      :normalizer => lambda {|t| t.strip}
    },
    "state" => {
      :friendly_name => "State",
      :value_getter => lambda {|v,h| [v.location.state || ""]},
      :normalizer => lambda {|t| t.strip}
    },
    "zip" => {
      :friendly_name => "Postal Code",
      :value_getter => lambda {|v,h| [v.location.postalCode || ""]},
      :normalizer => lambda {|t| t.gsub(/[ -.]/, '').strip}
    },
    "phone" => {
      :friendly_name => "Phone",
      :value_getter => lambda {|v,h| [v.contact.phone || ""]},
      :normalizer => lambda {|t| t.gsub(/\D/, '')}
    },
    "twitter" => {
      :friendly_name => "Twitter",
      :value_getter => lambda {|v,h| [v.contact.twitter || ""]},
      :normalizer => lambda {|t|
        return "" if t.nil? or t.length == 0
        return (t || " ").split('?').first.split('/').last.downcase
      }
    },
    "facebookUrl" => {
      :friendly_name => "Facebook",
      :value_getter => lambda {|v,h| [v.contact.facebook || "", v.contact.facebookUsername || ""]},
      :normalizer => lambda {|t|
        return "" if t.nil? or t.length == 0
        return (t || " ").split('?').first.split('/').last.downcase
      }
    },
    "instagram" => {
      :friendly_name => "Instagram",
      :value_getter => lambda {|v,h| [v.contact.instagram || ""]},
      :normalizer => lambda {|t|
        return "" if t.nil? or t.length == 0
        return (t || " ").split('?').first.split('/').last.downcase
      }
    },
    "url" => {
      :friendly_name => "Web Page",
      :value_getter => lambda {|v,h| [v.url || ""]},
      :normalizer => lambda {|t| t.gsub(/\/$/, '').gsub(/https?:\/\//, '').downcase}
    },
    "menuUrl" => {
      :friendly_name => "Menu URL",
      :value_getter => lambda {|v,h| [v.menu.externalUrl || ""]},
      :normalizer => lambda {|t| t.gsub(/\/$/, '').gsub(/https?:\/\//, '').downcase}
    },
    "parentId" => {
      :friendly_name => "Parent ID",
      :value_getter => lambda {|v,h| v.parent ? [v.parent.id] : [""]},
      :normalizer => lambda {|t| t.strip}
    },
    "hours" => {
      :friendly_name => "Hours",
      :value_getter => lambda do |v,h|
          result = []
          if !h.hours.timeframes.nil?
            h.hours.timeframes.each do |timeframe|
              timeframe.days.each do |day|
                timeframe.open.each do |segment|
                  result.push "#{day},#{segment['start']},#{segment['end']}"
                end
              end
            end
          end
          return [result.sort.join(";")]
        end,
      :normalizer => lambda {|t| t.split(/;/).sort.uniq.join(";") },
      :friendly_value => lambda do |val|
        val.split(/;/).map do |tf|
          (day, open, close) = tf.split(',')
          next if close.nil?
          open = open.gsub(/([0-9][0-9])([0-9][0-9])$/,'\1:\2')
          close = close.gsub(/([0-9][0-9])([0-9][0-9])$/,'\1:\2')
          "#{DAYS[day.to_i]}: #{open} - #{close}"
        end.join(", ")
      end
    },
    "description" => {
      :friendly_name => "Description",
      :value_getter => lambda {|v,h| [v.description.nil? ? "" : v.description]},
      :normalizer => lambda {|t| t.strip}
    },
    "venuell" => {
      :friendly_name => "Lat/Lng",
      :value_getter => lambda {|v,h| ["#{v.location.lat},#{v.location.lng}"]},
      :normalizer => lambda {|t| t.split(",").map{|e| e.slice(0,8)}.join(',') }
    }

  }

  def submithelper
    params = self.edits['newvalues'].keep_if {|k, v| KNOWN_FIELDS.keys.include? k}.merge(:comment => comment_text)
    client.propose_venue_edit(venueId, params)
  end

  def resolvedhelper?(venue)
    result = true

    if edits['newvalues'].include? 'hours'
      hours = client.venue_hours(venueId)
    else
      hours = nil
    end

    edits['newvalues'].each do |field, value|
      values = KNOWN_FIELDS[field][:value_getter].call(venue, hours)
      normalizedValues = values.map do |realValue|
        KNOWN_FIELDS[field][:normalizer].call(realValue)
      end

      found = normalizedValues.include? KNOWN_FIELDS[field][:normalizer].call(value)
      if (!found)
        logger.debug "venue {#{venueId}: edit not accepted: #{field}, looking for #{normalizedValues} found #{KNOWN_FIELDS[field][:normalizer].call(value)}"
      end

      result &= found
    end
    if !result
      # Let's see if any of the fields have changed:
      edits['oldvalues'].each do |field, value|
        # values = KNOWN_FIELDS[field][:value_getter].call(venue)
        if (! KNOWN_FIELDS[field][:value_getter].call(venue, hours).include? value)
          self.status = 'alternate resolution'
          self.resolved_details = "(changed)"
        end
      end
    end
    result
  end

  # TODO: Factor up to flag with good parameters
  def getVenueOrResolve
    begin
      venue = client.venue(venueId)

      if primary_id_changed?(venue)
        self.status = 'alternate resolution'
        self.resolved_details = '(merged)'
        save

        return true
      end

      if is_closed?(venue)
        self.status = 'alternate resolution'
        self.resolved_details = '(closed)'
        self.save
        return true
      end

      return venue
    rescue Foursquare2::APIError => e
      if e.message =~ /has been deleted/ or e.message =~ /is invalid for venue id/
        self.status = 'alternate resolution'
        self.resolved_details = '(deleted)'
        self.save
        return true
      else
        raise e
      end
    end
  end

  # TODO: Factor this up too
  def resolved?
    return true if status == 'resolved'
    return false if status == 'queued'

    resolved = false
    venue = getVenueOrResolve()
    if (venue === true)
      return true
    else
      resolved = resolvedhelper?(venue)
      self.status = 'resolved' if resolved
      self.resolved_details = nil if resolved
    end

    self.last_checked = Time.now
    self.save

    resolved
  end

  def friendly_name
    "Edit Venue Details"
  end

  def details
    friendly_edited_fields.map {|change| "#{change[:field]}: #{change[:value]}"}
  end

  def friendly_edited_fields
    edits['newvalues'].keep_if {|k, v| KNOWN_FIELDS.keys.include? k}.map do |k, v|
      v = '""' if v.empty?
      {:field => KNOWN_FIELDS[k][:friendly_name],
       :value => (KNOWN_FIELDS[k].include? :friendly_value) ? KNOWN_FIELDS[k][:friendly_value].call(v) : v }
    end.to_a
  end
end
