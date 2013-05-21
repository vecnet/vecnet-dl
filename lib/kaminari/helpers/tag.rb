# Monkey patch to remove sufia monkey patch on Kaminari
module Kaminari
  module Helpers
    class Tag
      def page_url_for(page)

      end
    end
  end
end
