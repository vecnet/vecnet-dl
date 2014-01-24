module CurationConcern
  module WithFullText
    extend ActiveSupport::Concern

    included do
      has_file_datastream "full_text", versionable: false
    end

    def extract_content
      url = Blacklight.solr_config[:url] ? Blacklight.solr_config[:url] : Blacklight.solr_config["url"] ? Blacklight.solr_config["url"] : Blacklight.solr_config[:fulltext] ? Blacklight.solr_config[:fulltext]["url"] : Blacklight.solr_config[:default]["url"]
      uri = URI(url+'/update/extract?extractOnly=true&wt=ruby&extractFormat=text')
      req = Net::HTTP.new(uri.host, uri.port)
      resp = req.post(uri.to_s, self.content.content, {'Content-type'=>self.mime_type+';charset=utf-8', "Content-Length"=>"#{self.content.content.size}" })
      extracted_text = resp.code.eql?("200") ? eval(resp.body)[""].rstrip : "#{resp.code}:#{resp.message}"
      self.full_text.mimeType='text/plain'
      self.full_text.content = extracted_text if extracted_text.present?
      save unless self.new_object?
    end

  end
end
