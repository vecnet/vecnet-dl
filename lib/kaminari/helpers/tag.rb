# Monkey patch to remove sufia monkey patch on Kaminari
module Kaminari
  module Helpers
    class Tag
      def page_url_for(page)
        @template.url_for @params.merge(@param_name => (page <= 1 ? nil : page)).symbolize_keys
      end
    end
  end
end
