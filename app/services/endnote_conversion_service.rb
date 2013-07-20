require 'mods'
class EndnoteConversionService

  attr_accessor :file, :bibutils_exec, :mods_xml, :parsed_mods

  def initialize(endnote_file)
    @file = endnote_file
    @bibutils_exec = "#{Rails.root}/bibutils/end2xml"
    @mods_xml="#{Rails.root}/tmp/#{File.basename(endnote_file)}"
  end

  def convert_to_mods
    `#{self.bibutils_exec} #{self.file} > #{self.mods_xml}`
  end

end
