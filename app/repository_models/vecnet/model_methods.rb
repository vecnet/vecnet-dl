module Vecnet
  module ModelMethods
    extend ActiveSupport::Concern

    def get_formated_date_created(create_date=nil)
      return nil if create_date.blank?
      return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.nil?
      pub_date=create_date.first
      if create_date.size>1
        logger.error "#{self.pid} has more than one pub date, #{create_date.inspect}, but will only use #{pub_date} for sorting"
      end
      pub_date_replace=pub_date.gsub(/-|\/|,|\s/, '.')
      @pub_date_sort=pub_date_replace.split('.').size> 1? Chronic.parse(pub_date) : Date.strptime(pub_date,'%Y')
      return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.blank?
    end


    def rights_english
      [self.rights].flatten.compact.map do |right|
        if right.start_with?("http")
          license_name = Sufia.config.cc_licenses.key(right)
          right = "#{license_name} [#{right}]" unless license_name.nil?
        end
        right
      end
    end

  end
end
