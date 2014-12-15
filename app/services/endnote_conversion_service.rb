require 'mods'
class EndnoteConversionService

  class EndnoteError < StandardError
  end

  # read the file name passed in.
  # yield each record in the file one-by-one
  def self.each_record(endnote_group_filename)
    File.open(endnote_group_filename, "r:bom|utf-8") do |f|
      record = []
      f.lines do |line|
        ln = line.strip
        unless ln.blank?
          if ln.start_with?("%0")
            yield record.join("\n") unless record.empty?
            record = []
          end
          record << ln
        end
      end
      yield record.join("\n") unless record.empty?
    end
  end

  # converts endnote text "%0 ..." into a hash and returns it
  def self.parse_single_record(record)
    result = {}
    tag = nil
    record.lines do |line|
      next if line.blank?
      if line.start_with?("%")
        tag_text = line[0..1]
        line = line[2..-1]
        tag = self.endnote_tags[tag_text]
        throw "Unknown endnote tag #{tag_text}" if tag.nil?
        result[tag] ||= []
      end
      throw "Tag is nil? line = '#{line}'" if tag.nil?
      result[tag] << line.strip
    end
    return result
  end

  # long list of endnote (v6?) tags
  # I think the newer endnote (v9?) uses multiletter tags
  # see http://endnote.com/sites/en/files/support/endnotex6machelp.pdf
  # page 122
  def self.endnote_tags
    @tags ||= {
      '%A' => :author,
      '%B' => :title_secondary,
      '%C' => :publish_place,
      '%D' => :publish_year,
      '%E' => :editor,
      '%F' => :label,
      '%G' => :language,
      '%H' => :author_translated,
      '%I' => :publisher,
      '%J' => :journal,
      '%K' => :keywords,
      '%L' => :call_number,
      '%M' => :accession_number,
      '%N' => :issue_number,
      '%O' => :title_alternate,
      '%P' => :pages,
      '%Q' => :title_translated,
      '%R' => :doi,
      '%S' => :title_tertiary,
      '%T' => :title,
      '%U' => :url,
      '%V' => :volume,
      '%W' => :database_provider,
      '%X' => :abstract,
      '%Y' => :author_tertiary,
      '%Z' => :notes,
      '%0' => :type,
      '%1' => :custom1,
      '%2' => :custom2,
      '%3' => :custom3,
      '%4' => :custom4,
      '%6' => :number_of_volumes,
      '%7' => :edition,
      '%8' => :date,
      '%9' => :type_of_work,
      '%?' => :author_subsidiary,
      '%@' => :isbn,
      '%!' => :title_short,
      '%#' => :custom5,
      '%$' => :custom6,
      '%]' => :custom7,
      '%&' => :section,
      '%(' => :original_publication,
      '%)' => :reprint_edition,
      '%*' => :reviewed_item,
      '%+' => :author_address,
      '%^' => :caption,
      '%>' => :files,
      '%<' => :research_notes,
      '%[' => :access_date,
      '%=' => :custom8,
      '%~' => :database_name,
    }
  end
end
