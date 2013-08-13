class CommentDatastream < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(:path=>"fields", :xmlns => '', :namespace_prefix => nil)
    t.comments(:xmlns => '', :namespace_prefix => nil) {
      t.version_id(:index_as=>[:searchable],:path=>{:attribute=>"version"})
    }
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.fields
    end
    builder.doc
  end
end
