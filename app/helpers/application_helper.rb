module ApplicationHelper
  include GenericFileHelper
  def construct_show_path(solr_document, options={})
    noid = solr_document["noid_s"].first
    object_type = solr_document.fetch('has_model_s', [""]).first
    if object_type.end_with?("info:fedora/afmodel:Citation")
      citations_path(noid)
    else
      files_path(noid)
    end
  end

  def construct_show_url(solr_document, options={})
    noid = solr_document["noid_s"].first
    object_type = solr_document.fetch('has_model_s', [""]).first
    if object_type.end_with?("info:fedora/afmodel:Citation")
      citations_url(noid)
    else
      files_url(noid)
    end
  end

  def get_first_title args
    value ||= args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
    render_field_value value.first
  end

  def help_icon(key)
    link_to '#', id: "generic_file_#{key.to_s}_help", rel: 'popover',
            'data-content' => metadata_help(key).html_safe,
            'data-original-title' => get_label(key) do
      content_tag 'i', '', class: "icon-question-sign icon-large"
    end
  end

  def curation_concern_attribute_to_url_html(curation_concern, method_name, label, options = {})
    markup = ""
    subject = curation_concern.send(method_name)
    return markup if !subject.present? && !options[:include_empty]
    markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
    [subject].flatten.compact.each do |value|
      markup << %(<li class="attribute #{method_name}"><a href="#{value}" target="_blank">#{h(value)}</a></li>\n)
    end
    markup << %(</ul></td></tr>)
    markup.html_safe
  end

  def custom_value_to_html(curation_concern, label, options = {})
    markup = ""
    version=curation_concern.send(:current_version_just_id)
    noid_with_version = version.blank? ? nil : "#{curation_concern.send(:noid)}/#{version}"
    return markup if !noid_with_version.present? && !options[:include_empty]
    markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
    [noid_with_version].flatten.compact.each do |v|
      markup << %(<li class="attribute">#{h(v)}</li>\n)
    end
    markup << %(</ul></td></tr>)
    markup.html_safe
  end

  def check_version?(curation_concern)
    if params.has_key?(:version)
      curation_concern.current_version_just_id == params[:version]
    else
      true
    end
  end

  def tag_each(xml, fieldname, values)
    return if values.nil?
    if ! values.respond_to?(:each)
      xml.tag!(fieldname, values)
      return
    end
    values.each do |v|
      xml.tag!(fieldname, v)
    end
  end

end
