class SubmitFlagJob < Struct.new(:flag, :token)

  def perform
    flag.submit(token)
  end

  def success(job)
    flag.job_id = nil
    flag.save
  end

  def error(job, exception)
    @exception = exception
    if exception.is_a?(OpenSSL::SSL::SSLError)
      flag.update_attributes(status: 'failed', resolved_details: "SSL error: #{exception.message}")
      job.destroy
    elsif exception.is_a?(Foursquare2::APIError) && exception.type == 'rate_limit_exceeded'
      Rails.logger.warn "Rate limited on flag #{flag.id}"
    end
  end

  def failure(job)
    flag.job_id = nil
    flag.status = "failed"
    flag.save
  end

  def max_attempts
    # Retries happen at 5 + n^4 seconds, where n = number of attempts
    # 12 gives last retry at 6 hours
    return 12
  end

  def reschedule_at(time_now, attempts)
    if (@exception.is_a?(Foursquare2::APIError) && @exception.type == 'rate_limit_exceeded')
      time_now + 120
    else
      time_now + (attempts ** 4) + 5
    end
  end

end
