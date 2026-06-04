class CheckFlagJob < Struct.new(:flag, :token)

  def perform
    flag.access_token = token
    flag.resolved?
  end

  def error(job, exception)
    @exception = exception
    if exception.is_a?(OpenSSL::SSL::SSLError)
      job.destroy
    elsif exception.is_a?(Foursquare2::APIError) && ['invalid_auth', 'not_authorized', 'param_error'].include?(exception.type)
      job.destroy
    elsif exception.is_a?(Foursquare2::APIError) && exception.type == 'rate_limit_exceeded'
      Rails.logger.warn "Rate limited on flag #{flag.id} check"
    end
  end

  def reschedule_at(time_now, attempts)
    if (@exception.is_a?(Foursquare2::APIError) && @exception.type == 'rate_limit_exceeded')
      time_now + 120
    else
      time_now + (attempts ** 4) + 5
    end
  end

end
