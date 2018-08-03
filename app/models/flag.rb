class Flag < ActiveRecord::Base
  belongs_to :user
  attr_accessible :created_at, :primaryName, :venueId,
                  :status, :type, :user, :problem,
                  :comment, :scheduled_at, :venues_details
  attr_accessor :access_token
  serialize :venues_details, JSON

  validates_presence_of :venueId, :on => :create, :message => "can't be blank"
  # validates_inclusion_of :status, :in => %w( new resolved submitted ), :message => "extension %s is not included in the list"
  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  HOME_CAT_ID = '4bf58dd8d48988d103941735';

  def user_token
    # TODO: remove the user.oauth_token and ONLY use self.access_token
    @token ||= ( self.access_token.present? ) ? self.access_token : user.oauth_token
  end

  def client
    @user_client ||= Foursquare2::Client.new(:oauth_token => user_token, :connection_middleware => [Faraday::Response::Logger, FaradayMiddleware::Instrumentation], :api_version => '20140825')
  end

  def userless_client
    @userless_client ||= Foursquare2::Client.new(:client_id => Settings.app_id, :client_secret => Settings.app_secret, :connection_middleware => [Faraday::Response::Logger, FaradayMiddleware::Instrumentation], :api_version => '20140825')
  end

  def queue_for_submit(token, delayed_time = Time.now, queue = 'submit')
    if self.job_id
      begin
        # Delete job if it is already present
        Delayed::Job.find(self.job_id).destroy
      rescue ActiveRecord::RecordNotFound => e
        # No big deal, we can ignore it
      end
    end

    unless self.scheduled_at.nil?
      if (scheduled_at > Time.now)
        delayed_time = scheduled_at
      else
        if type == "MergeFlag"
          delayed_time = Time.now + 6.minutes
        else
          delayed_time = Time.now + 5.minutes
        end
      end
      queue = 'scheduled_close'
      self.status = 'scheduled'
    else
      self.status = 'queued'
    end

    if type == 'RemoveCategoryFlag'
      # we remove cats first, since they can sometimes affect other flags
      priority = 10
      delayed_time = delayed_time - 20.seconds
    elsif type == 'PhotoFlag'
      priority = 50
    else
      priority = 20
    end

    job = Delayed::Job.enqueue(SubmitFlagJob.new(self, token), :priority => priority, :run_at => delayed_time, :queue => queue)
    self.job_id = job.id
    save
  end

  def submit(delayed_token)
    if status == 'canceled' || status == 'resolved'
      return
    end
    self.access_token = delayed_token
    begin
      result = submithelper
    rescue Foursquare2::APIError => e
      if e.message =~ /not_authorized/
        self.update_attribute('status', 'not_authorized')
        return
      end
      if e.message =~ /has been deleted/
        self.update_attribute('status', 'resolved')
        self.update_attribute('resolved_details', '(deleted)') unless type == 'DeleteFlag'
        return
      end
      raise e
    end
    if (self.creatorId.nil? && result && result['creator'])
      self.creatorId = result['creator']['id']
      self.creatorName = ((result['creator']['firstName'] || "") + " " + (result['creator']['lastName'] || "")).strip
    end
    self.status = 'submitted'
    self.submitted_at = Time.now
    self.save
    delay(:run_at => 20.seconds.from_now, :queue => 'check', :priority => (type == "PhotoFlag" ? 55 : 45)).resolved?

    flag_json = "NO FLAGS"
    if result && result.flags
      flag_json = result.flags.to_json
    elsif result && result.woes
      flag_json = result.woes.to_json
    end
    Rails.logger.info("RESPONSE: #{id}\t#{type}\t#{flag_json}")
    result
  end

  def cancel
    if status == 'new' or status == 'queued' or status == 'scheduled'
      self.status = 'canceled'
      if self.job_id
        Delayed::Job.find(self.job_id).destroy
        self.job_id = nil
      end
      save
    end
  end

  def hide
    self.update_attribute('status', 'hidden')
  end

  # return true if the venue has home as a secondary category
  def has_home?(venue)
    catIds = venue.categories.map {|e| e.id}
    return catIds.length > 0 && catIds.include?(HOME_CAT_ID) && catIds.first != HOME_CAT_ID
  end

  # return true if the venue passed has home as a primary category
  def is_home?(venue)
    catIds = venue.categories.map {|e| e.id}
    return catIds.length > 0 && catIds.first == HOME_CAT_ID
  end

  # return true if the venue passed has home as a primary category
  def primary_id_changed?(primaryVenue)
    return primaryVenue.id != venueId
  end

  def is_closed?(venue)
    return venue.closed == true
  end

  def comment_text
    if comment.nil?
      ""
    else
      comment.strip
    end
  end

  def job
    if @jobCache
      return @jobCache
    end

    if self.job_id
      begin
        @jobCache = Delayed::Job.find(self.job_id)
        return @jobCache
      rescue ActiveRecord::RecordNotFound => e
        # Rollbar.report_exception(e)
        return false
      end
    else
      false
    end
  end

  def scheduled_time
    if job
      job.run_at
    end
  end

  def delayed_due_to_rate_limit
    job && !job.last_error.nil? && job.last_error.include?("rate_limit_exceeded")
  end

  def flag_type
    type.to_s
  end

  def details
  end

  def as_json(options = {})
    super options.merge(:methods => [:friendly_name, :flag_type, :details, :user_token])
  end
end
