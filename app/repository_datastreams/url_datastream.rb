class UrlDatastream < ActiveFedora::Datastream
  def self.default_attributes
    super.merge(:controlGroup => 'M', :mimeType => 'text/url', :label => 'URL')
  end

  def file_location
    self.content
  end

  def file_location=(value)
    URI.parse(value) unless value.nil?
    self.content = value
  end
end