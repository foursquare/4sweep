module ApplicationHelper

  def api_version
    "20140825"
  end

  def total_flags
    #Flag.count()
    # Hack alert: this is hacky, but much faster than .count()
    Flag.maximum(:id)
  end

  def release
    "0.30.17"
  end
end
