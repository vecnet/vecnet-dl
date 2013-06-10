class MeshDataParser

  attr_accessor :file

  def initialize(file)
    @file = file
  end

  def each_mesh_record
    current_data = {}
    in_record = false
    self.file.each_line do |line|
      case line
      when /\A\*NEWRECORD/
        yield(current_data) if in_record
        in_record = true
        current_data = {}
      when /\A(?<label>\w+) = (?<value>.*)/
        current_data[Regexp.last_match(:label)] ||= []
        current_data[Regexp.last_match(:label)] << Regexp.last_match(:value)
      when /\A\n/
        yield(current_data) if in_record
        in_record = false
      end
    end
    # final time in case file did not end with a blank line
    yield(current_data) if in_record
  end

  def all_records
    result = []
    self.each_mesh_record {|rec| result << rec }
    return result
  end

  def self.get_synonyms(record)
    puts record.inspect
    synonymns=[]
    record['ENTRY'].each do |synonym|
      synonymns<<synonym.split(/|/).first
    end
    synonymns
  end

  def self.get_description(record)
    puts record.inspect
    descriptions=[]
    record['MS'].each do |desc|
      descriptions<<desc
    end
    descriptions
  end

  def self.get_tree(record)
    puts record.inspect
    tree=[]
    record['MN'].each do |tree_id|
      tree<<tree_id
    end
    tree
  end

  def self.get_label(record)
    puts record.inspect
    labels=[]
    record['MH'].each do |label|
      labels<<label
    end
    labels
  end
  def self.get_label_downcase(record)
    puts record.inspect
    labels=[]
    record['MH'].each do |label|
      labels<<label.downcase
    end
    labels
  end

end
