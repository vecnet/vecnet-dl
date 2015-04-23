module Admin
  class UsageController < ApplicationController

    def index
      @events = UsageEvent.order("event_time").limit(20)
    end

  end
end
