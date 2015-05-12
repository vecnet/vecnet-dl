module Admin
  class UsageController < ApplicationController

    helper :report

    def index
      # get result and repackage it as we intend to display it
      @start = date_from_hash(params[:start])
      @end = date_from_hash(params[:end])
      result = UsageEvent.resource_reporting(@start, @end)
               .group_by { |r| r["resource_type"] }
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

    def date_from_hash(hash, default=nil)
      return default if hash.nil?
      return nil if hash[:year] == ""
      hash[:month] = 1 if hash[:month] == ""
      hash[:day] = 1 if hash[:day] == ""
      Date.new(hash[:year].to_i, hash[:month].to_i, hash[:day].to_i)
    end

  end
end
