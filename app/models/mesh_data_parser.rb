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
      when /\A(?<term>\w+) = (?<value>.*)/
        current_data[Regexp.last_match(:term)] ||= []
        current_data[Regexp.last_match(:term)] << Regexp.last_match(:value)
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
    puts record['ENTRY'].inspect
    synonymns=[]
    unless record['ENTRY'].blank?
      record['ENTRY'].each do |synonym|
        synonymns<<synonym.split('|').first
      end
    end
    synonymns
  end

  def self.get_description(record)
    puts record['MS'].inspect
    descriptions=[]
    unless record['MS'].blank?
      record['MS'].each do |desc|
        descriptions<<desc
      end
    end
    descriptions
  end

  def self.get_tree(record)
    puts record['MN'].inspect
    tree=[]
    unless record['MN'].blank?
      record['MN'].each do |tree_id|
        tree<<tree_id
      end
    end
    tree
  end

  def self.get_term(record)
    puts record['MH']
    record['MH'].first
  end

end
