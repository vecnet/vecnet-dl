module Admin
  class UsageController < ApplicationController

    def index
      @events = UsageEvent.order("event_time DESC").limit(200)
    end

  end
end
