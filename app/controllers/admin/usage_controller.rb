module Admin
  class UsageController < ApplicationController

    helper :report

    def index
      # get result and repackage it as we intend to display it
      @start = date_from_param(params[:start])
      @end = date_from_param(params[:end])
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

    def date_from_param(hash)
      return nil if hash.nil?
      return nil unless hash =~ /\A(\d{4})-(\d{1,2})-(\d{1,2})\Z/
      Date.new($1.to_i, $2.to_i, $3.to_i)
    end

  end
end
