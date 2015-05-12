module Admin
  class UsageController < ApplicationController

    helper :report

    def index
      # get result and repackage it as we intend to display it
      if params[:start]
        @start = Date.new(params[:start][:year].to_i, params[:start][:month].to_i, params[:start][:day].to_i)
      else
        @start = Date.today
      end
      if params[:end]
        @end = Date.new(params[:end][:year].to_i, params[:end][:month].to_i, params[:end][:day].to_i)
      else
        @end = Date.today
      end
      result = UsageEvent.resource_reporting(@start, @end)
      result = result.group_by { |r| r["resource_type"] }
      @total = {"view" => 0, "download" => 0}
      @table = result.map do |type, data|
        r = {"view" => 0, "download" => 0}
        data.each do |rec|
          @total[rec["event"]] += rec["count"]
          r[rec["event"]] = rec["count"]
        end
        [type, r]
      end
      @table << ["Total", @total]
    end

    def details
      @events = UsageEvent.order("event_time DESC").limit(200)
    end

  end
end
