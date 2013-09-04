module ApplicationHelper
  def construct_show_path(solr_document, options = {})
    object_type=solr_document.has?('has_model_s') ? solr_document['has_model_s'].first.gsub("info:fedora/afmodel:",'') : ""
    if object_type.eql?("Citation")
      return citations_path(solr_document[:noid_s].first)
    else
      return files_path(solr_document[:noid_s].first)
    end
  end

  def get_first_title args
    value ||= args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
    render_field_value value.first
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
      return curation_concern.current_version_just_id == params[:version] ? true : false
    else
      return true
    end
  end

end