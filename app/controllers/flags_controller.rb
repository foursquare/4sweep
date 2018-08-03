class FlagsController < ApplicationController
  before_filter :require_user

  FLAG_TYPES = {
    "merge_flags" => {
      :types => ["MergeFlag"],
      :name =>"Duplicate"
    },
    "category_flags" => {
      :types => ["AddCategoryFlag", "MakeHomeFlag", "RemoveCategoryFlag", "MakePrimaryCategoryFlag", "ReplaceAllCategoriesFlag"],
      :name => "Category"
    },
    "close_venue_flags" => {
      :types => ["CloseFlag", "ReopenFlag"],
      :name => "Close"
    },
    "private_venue_flags" => {
      :types => ["MakePrivateFlag", "MakePublicFlag"],
      :name => "Private"
    },
    "remove_venue_flags" => {
      :types => ["DeleteFlag", "UndeleteFlag"],
      :name => "Remove"
    },
    "photo_flags" => {
      :types => ["PhotoFlag"],
      :name => "Photo"
    },
    "tip_flags" => {
      :types => ["TipFlag"],
      :name => "Tip"
    },
    "edit_venue_flags" => {
      :types => ["EditVenueFlag"],
      :name => "Venue Details"
    }
  }

  def index
    @status = params[:status] || "new"

    @status_types = [@status]
    if params[:status] == 'hidden/canceled'
      @status_types = ['hidden', 'canceled', 'cancelled']
    end

    @flag_types = FLAG_TYPES

    @pagesize = (params[:pagesize] || 100).to_i

    if (params[:include_types])
      @selected_types = params[:include_types].split(",").select {|e| FLAG_TYPES.has_key?(e)}
    else
      @selected_types = FLAG_TYPES.keys
    end

    types = @selected_types.map {|e| FLAG_TYPES[e][:types]}.flatten

    @known_statuses = ['new', 'submitted', 'resolved', 'queued', 'scheduled', 'canceled', 'cancelled', 'hidden', 'alternate resolution']

    @ordertype = (params.has_key? "order_last_checked" and @status == 'submitted') ? "last_checked" : "created_at"

    order = (@ordertype == 'last_checked') ? 'last_checked desc' : 'created_at desc'

    if params[:status] == "other"
      @flags = @current_user.flags.where("status NOT IN (?) and type IN (?)", @known_statuses, types).order(order).page(params[:page]).per(@pagesize)
    else
      @flags = @current_user.flags.where("status IN (?) and type IN (?)", @status_types, types).order(order).page(params[:page]).per(@pagesize)
    end

    @pagenum = params[:page] || 1;
    @unsubmitted_flags = @flags.select {|e| e.status == 'new'}
    @unresolved_flags  = @flags.select {|e| e.status == 'submitted'}
    @scheduled_flags  = @flags.select {|e| e.status == 'scheduled'}

    @flag_tabs = ['new', 'queued', 'submitted', 'resolved', 'scheduled', 'hidden/canceled', 'alternate resolution', 'other']

    @total_flags_counts = @current_user.flags.count(:group => :status)
    @total_flags_counts.default = 0

    @allflagscount = @total_flags_counts.values.sum
    @total_flags_counts['newcount'] = @total_flags_counts['queued'] + @total_flags_counts['new']
    @total_flags_counts['hidden/canceled'] = @total_flags_counts['canceled'] + @total_flags_counts['hidden'] +  @total_flags_counts['cancelled']

    @total_flags_counts['other'] = @allflagscount - @total_flags_counts.select {|k, v| @known_statuses.include? k}.values.sum

    @flagcount = @total_flags_counts['queued'] + @total_flags_counts['new']
    queuesize

    respond_to do |format|
      format.html
      format.json {render :json => @flags}
    end
  end

  def newcount
    render :json => {:newcount => newflags}, status => 200
  end

  def resubmit
    processflags do |flag|
      flag.resolved_details = nil
      flag.queue_for_submit(@current_user.oauth_token, Time.zone.now)
      flag
    end
  end

  def hide
    processflags do |flag|
      flag.status = 'hidden'
      flag.resolved_details = nil
      flag.save
    end
  end

  def flagtype(type)
    case type
      when "AddCategoryFlag" then AddCategoryFlag
      when "CloseFlag" then CloseFlag
      when "DeleteFlag" then DeleteFlag
      when "EditVenueFlag" then EditVenueFlag
      when "MergeFlag" then MergeFlag
      when "MakeHomeFlag" then MakeHomeFlag
      when "MakePrimaryCategoryFlag" then MakePrimaryCategoryFlag
      when "MakePrivateFlag" then MakePrivateFlag
      when "MakePublicFlag" then MakePublicFlag
      when "ReopenFlag" then ReopenFlag
      when "RemoveCategoryFlag" then RemoveCategoryFlag
      when "ReplaceAllCategoriesFlag" then ReplaceAllCategoriesFlag
      when "UndeleteFlag" then UndeleteFlag
      when "PhotoFlag" then PhotoFlag
      when "TipFlag" then TipFlag
      else
        raise "Invalid Flag Type"
    end
  end

  def create
    flags = []

    params[:flags].values.each do |flag|
      flag = flagtype(flag[:type]).new(flag)
      flag.user = @current_user
      flag.save!
      if params[:runimmediately] && params[:runimmediately] != 'false' or flag["scheduled_at"]
        flag.queue_for_submit(@current_user.oauth_token, 5.minutes.from_now)
      end
      flags << flag
    end

    respond_to do |format|
      format.json {render :json => {:flags => flags, :newcount => newflags}, :status => :created }
    end
  end

  def run
    processflags do |flag|
      flag.queue_for_submit(@current_user.oauth_token, Time.now)
    end
  end

  def check
    processflags do |flag|
      flag.resolved?
    end
  end

  def cancel
    processflags do |flag|
      flag.cancel
    end
  end

  def statuses
    allowed_statuses = ['new', 'submitted', 'queued', 'scheduled']

    if params.has_key? :venue_ids
      @flags = @current_user.
              flags.
              select('`id`, `venueId`, `user_id`, `secondaryVenueId`, `secondaryName`, `primaryName`, `itemId`, `type`, `status`, `itemName`, `problem`, `edits`, `created_at`, `last_checked`, `comment`, `scheduled_at`, `resolved_details`').
              where('(`venueId` IN (:ids) OR `secondaryVenueId` IN (:ids)) AND (`status`  IN (:statuses)) AND (`type` IN (:included_types))',
        :user_id => @current_user.id,
        :ids => params[:venue_ids],
        :statuses => allowed_statuses,
        :included_types => params[:types])
    elsif params.has_key? :creator_ids
      @flags = @current_user.
              flags.
              select('`id`, `venueId`, `user_id`, `secondaryVenueId`, `secondaryName`, `primaryName`, `itemId`, `type`, `status`, `itemName`, `problem`, `edits`, `created_at`, `last_checked`, `comment`, `scheduled_at`, `resolved_details`').
              where('creatorId IN (:ids) AND (`status`  IN (:statuses)) AND (`type` IN (:included_types))',
        :user_id => @current_user.id,
        :ids => params[:creator_ids],
        :statuses => allowed_statuses,
        :included_types => params[:types])
    end

    if params.has_key? :forcecheck
      response = @flags.each do |flag|
        tryflagaction(flag) do |c|
          c.resolved?
        end
      end
      response = response.select do |flag|
        allowed_statuses.include? flag.status
      end
      respond_to do |format|
        format.json {render :json => response, :status => 200}
      end
    else
      respond_to do |format|
        format.json {render :json => @flags, :status => 200}
      end
    end

  end

  private
  def processflags(&action)
    to_run = @current_user.flags.find(params[:ids])
    responses = []
    to_run.each do |flag|
      responses.push tryflagaction(flag, &action)
    end
    respond_to do |format|
      format.json {render :json => {:flags => responses, :newcount => newflags}}
    end
  end

  def tryflagaction(flag)
    begin
      yield flag
      return {:flag => flag}
    rescue Foursquare2::APIError => e
      if e.message =~ /quota exceeded/i
        return {:flag => flag, :message => "Quota Exceeded, Try Again Later"}
      elsif e.message =~ /Please retry/i
        return {:flag => flag, :message => "Try again later"}
      else
        # Rollbar.report_exception(e)
        return {:flag => flag, :message => "Unknown Error"}
      end
    rescue Faraday::Error::ParsingError => e
      return {:flag => flag, :message => "Foursquare Error: Try again later"}
    end
  end

  def queuesize
    now = Delayed::Job.db_time_now
    @queue_size = Delayed::Job.where('failed_at is null and run_at <= ?', Delayed::Job.db_time_now).count
  end

  def newflags
    @current_user.flags.count(:conditions => "status IN ('new', 'queued')")
  end
end
