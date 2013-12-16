class UrlDatastream < ActiveFedora::Datastream
  def self.default_attributes
    super.merge(:controlGroup => 'M', :mimeType => 'text/plain', :label => 'URL')
  end

  def file_location
    self.content
  end


  def file_location=(url)
   puts  "store location"
    u = URI::Parser.new.parse(url) unless url.nil?
    return if ![URI::HTTP, URI::HTTPS, URI::FTP, URI::Generic].include?(u.class) || u.scheme.eql?('javascript')
    puts "storing #{u} to url"
    self.content = u.to_s
  end

  def to_s
    file_location
  end

end