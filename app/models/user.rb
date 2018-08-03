class User < ActiveRecord::Base
  # TODO: remove token
  attr_accessible :enabled, :level, :name, :uid, :token
  attr_accessor :access_token
  has_many :flags

  serialize :user_cache, JSON
  MAX_USER_AGE = 1.hour

  def oauth_token
    # TODO: remove the self.token and ONLY use self.access_token
    @token ||= ( self.access_token.present? ) ? self.access_token : self.token
  end

  def foursquare_client
    foursquare ||= Foursquare2::Client.new(:oauth_token => oauth_token, :connection_middleware => [Faraday::Response::Logger, FaradayMiddleware::Instrumentation], :api_version => '20140825')
  end

  def foursquare_user
    if ((read_attribute :cached_at) == nil) or
          (Time.now - cached_at > MAX_USER_AGE)
      self.user_cache = filtered_user(foursquare_client.user('self'))
      self.name = "#{user_cache['firstName']} #{user_cache['lastName']}".strip
      self.cached_at = Time.now
      self.level = self.user_cache['superuser'] ? self.user_cache['superuser'] : ''
      self.hometown = self.user_cache['homeCity']
      save
    end
    user_cache
  end

  # Take a raw user object from Foursquare and
  # keep only the few fields we're interested in caching:
  #  firstName, photo,
  def filtered_user(raw_user)
    if raw_user['checkins'] && raw_user. checkins.items.count > 0
      recentCheckin = raw_user.checkins.items.first.venue.location
    else
      recentCheckin = {'lat' => nil, 'lng' => nil}
    end
    result = {
      'id' => raw_user['id'],
      'firstName' => (raw_user['firstName'] || "").gsub(/[^\u0000-\uFFFF]/, ''),
      'lastName' => (raw_user['lastName'] || "").gsub(/[^\u0000-\uFFFF]/, ''),
      'photo' => raw_user['photo'].to_hash,
      'homeCity' => (raw_user['homeCity'] || "").gsub(/[^\u0000-\uFFFF]/, ''),
      'superuser' => raw_user['superuser'],
      'checkins' => {
        'items' => [
          {
            'venue' => {
              'location' => {
                'lat' => recentCheckin['lat'],
                'lng' => recentCheckin['lng']
              }
            }
          }
        ]
      }
    }
  end

  def photo_src(size='36x36')
    if foursquare_user['photo']
      return "#{foursquare_user['photo']['prefix']}#{size}#{foursquare_user['photo']['suffix']}"
    else
      # Rollbar.report_message("User missing photo hash: #{foursquare_user}")
      return ""
    end
  end

  def recent_ll
    u = foursquare_user
    [foursquare_user['checkins']['items'].first['venue']['location']['lat'],
     foursquare_user['checkins']['items'].first['venue']['location']['lng']]
  end

  def allowed?
    enabled
  end

  def is_admin?
    false # REPLACE_ME
  end

end
