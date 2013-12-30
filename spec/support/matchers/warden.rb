#require 'warden'
module Warden
  # Warden::Test::ControllerHelpers provides a facility to test controllers in isolation
  # Most of the code was extracted from Devise's Devise::TestHelpers.
  module Test
    module ControllerHelpers
      def self.included(base)
        base.class_eval do
          setup :setup_controller_for_warden, :warden if respond_to?(:setup)
        end
      end

      # Override process to consider warden.
      def process(*)
        # Make sure we always return @response, a la ActionController::TestCase::Behavior#process, even if warden interrupts
        _catch_warden {super} || @response
      end

      # We need to setup the environment variables and the response in the controller
      def setup_controller_for_warden
        @request.env['action_controller.instance'] = @controller
      end

      # Quick access to Warden::Proxy.
      def warden
        @warden ||= begin
          manager = Warden::Manager.new(nil, &Rails.application.config.middleware.detect{|m| m.name == 'Warden::Manager'}.block)
          @request.env['warden'] = Warden::Proxy.new(@request.env, manager)
        end
      end

      protected

      # Catch warden continuations and handle like the middleware would.
      # Returns nil when interrupted, otherwise the normal result of the block.
      def _catch_warden(&block)
        result = catch(:warden, &block)

        env = @controller.request.env

        result ||= {}

        # Set the response. In production, the rack result is returned
        # from Warden::Manager#call, which the following is modelled on.
        case result
          when Array
            if result.first == 401 && intercept_401?(env) # does this happen during testing?
              _process_unauthenticated(env)
            else
              result
            end
          when Hash
            _process_unauthenticated(env, result)
          else
            result
        end
        result
      end

      def _process_unauthenticated(env, options = {})
        options[:action] ||= :unauthenticated
        proxy = env['warden']
        result = options[:result] || proxy.result

        ret = case result
                when :redirect
                  body = proxy.message || "You are being redirected to #{proxy.headers['Location']}"
                  [proxy.status, proxy.headers, [body]]
                when :custom
                  proxy.custom_response
                else
                  [401, {"Content-Type" => "text/plain"}, "Authorization Failed"]
              end

        # ensure that the controller response is set up. In production, this is
        # not necessary since warden returns the results to rack. However, at
        # testing time, we want the response to be available to the testing
        # framework to verify what would be returned to rack.
        if ret.is_a?(Array)
          # ensure the controller response is set to our response.
          @controller.response ||= @response
          @response.status = ret.first
          @response.headers = ret.second
          @response.body = ret.third
        end

        ret
      end
    end
  end
end