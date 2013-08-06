require 'mods'
class EndnoteConversionService

  class EndnoteError < StandardError
  end

  def self.each_record(endnote_group_filename)
    File.open(endnote_group_filename) do |f|
      record = []
      f.lines do |line|
        ln = line.strip
        if ln != ""
          if ln.start_with?("%0")
            yield record.join("\n")
            record = []
          end
          record << ln
        end
      end
      yield record.join("\n") if record.length > 0
    end
  end

  attr_accessor :endnote_filename, :mods_xml_filename

  def initialize(endnote_file, mods_file=nil)
    @endnote_filename = endnote_file
    @mods_xml_filename = mods_file
  end

  def convert_to_mods
    # assumes end2xml is in path
    modsxml = `end2xml #{self.endnote_filename}`
    s = $?.exitstatus
    if s > 0
      puts "Error running end2xml: exit code #{s}"
      puts modsxml
      raise EndnoteError, "end2xml exit code #{s}"
    end
    if mods_xml_filename
      File.open(mods_xml_filename) { |f| f.write(modsxml) }
    end
  end
end
