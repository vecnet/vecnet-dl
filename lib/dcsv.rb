class Dcsv
  # Takes an input string in the DCSV format
  # (see http://dublincore.org/documents/dcmi-dcsv/ )
  # and returns a hash.
  #
  # TODO: This does not handle the '.' scope operator at all
  def self.decode(input_string)
    result = {}
    unlabeled_count = 0
    value_list = input_string.split(/(?<!\\);/)
    value_list.each do |value|
      value.gsub!(/\\;/,';') # unescape ;
      label, rest = value.split(/(?<!\\)=/,2)
      label.gsub!(/\\=/, '=')
      rest.gsub!(/\\=/, '=') if rest
      if rest
        # label is trimmed of whitespace, by spec rest is not trimmed.
        label.strip!
        result[label] = rest
      else
        result[unlabeled_count] = label
        unlabeled_count += 1
      end
    end
    result
  end

  # takes an input hash or string and converts it
  # into the DCSV format. Returns a string.
  def self.encode(input)
    if input.is_a?(Hash)
      result = []
      input.each_pair do |k,v|
        if k.is_a?(Integer)
          result << encode(v)
        else
          result << "#{encode(k)}=#{encode(v)}"
        end
      end
      result.join(";")
    else
      input.to_s.gsub(/([=;])/) { "\\#{$1}" }
    end
  end
end
