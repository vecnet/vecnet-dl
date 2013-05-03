object curation_concern
attributes :pid, :title

node(:metadata) do
  result={}
  [:description, :depositor, :related_url, :based_near, :part_of, :creator, :contributor, :tag, :rights, :publisher,
        :date_created, :subject, :resource_type, :identifier, :language, :spatials, :temporals].each {|term|
          result[term] = curation_concern.send(term) if curation_concern.send(term).present?
        }

  result
end

node(:charactization) do
   result={}
   [:mime_type, :format_label,  :file_size,  :last_modified,  :filename,
          :original_checksum,  :rights_basis,  :copyright_basis,  :copyright_note,
          :well_formed,  :valid,  :status_message,  :file_title,  :file_author,  :page_count,  :file_language,  :word_count,
          :character_count,  :paragraph_count,  :line_count,  :table_count,  :graphics_count,  :byte_order,
          :compression,  :width,  :height,  :color_space,  :profile_name,  :profile_version,  :orientation,  :color_map,  :image_producer,
          :capture_device,  :scanning_software,  :exif_version,  :gps_timestamp, :character_set,  :markup_basis,
          :markup_language,  :duration,  :bit_depth,  :sample_rate, :channels,  :data_format,  :offset].each { |term|
          result[term] = curation_concern.send(term) if curation_concern.send(term).present?
   }
  result

end

node(:user_name) do
  if current_user?
    current_user.to_s
  end
end

#node(:charactization) do
#  data= [:mime_type, :format_label,:file_size,:original_checksum, :filename].map.each {|term|
#          {term=> curation_concern.send(term)}}
#  data.keep_if{|term| term.values.first.present?}
#end
