class EndNote
  def initialize(object)
    @object=object
  end

  def to_s
    @object.to_s
  end

  def to_endnote
    type= @object.respond_to?(:human_readable_type) ? @object.human_readable_type : @object.class
    end_note_format = {
        '%T' => [:title, lambda { |x| x.is_a?(Array)? x.first : x }],
        '%Q' => [:title, lambda { |x| x.is_a?(Array)? x.slice(1, -1) : '' }],
        '%A' => [:creator],
        '%C' => [:publication_place],
        '%D' => [:date_created],
        '%8' => [:date_uploaded],
        '%E' => [:contributor],
        '%I' => [:publisher],
        '%J' => [:series_title],
        '%@' => [:isbn],
        '%U' => [:related_url],
        '%7' => [:edition_statement],
        '%R' => [:persistent_url],
        '%X' => [:description],
        '%G' => [:language],
        '%[' => [:date_modified],
        '%9' => [:resource_type],
        '%~' =>  CurateNd::Application::config.application_name,
        '%W' => 'TBD'
    }
    text = []
    text << "%0 #{type}"
    end_note_format.each do |endnote_key, mapping|
      puts "Key:#{endnote_key}, Mapping:#{mapping}, #{mapping.class}"
      if mapping.is_a? String
        values = [mapping]
      else
        values = @object.send(mapping[0]) if @object.respond_to? mapping[0]
        puts "1: #{values}"
        values = mapping[1].call(values) if mapping.length == 2
        puts "2: #{values}"
        values = [values] unless values.is_a? Array
        puts "3: #{values}"
      end
      next if values.empty? or values.first.nil?
      spaced_values = values.join("; ")
      text << "#{endnote_key} #{spaced_values}"
    end
    return text.join("\n")
  end
  
  def get_title
    puts @object.title
    @object.title
  end
  
end