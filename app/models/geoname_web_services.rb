
module GeonameWebServices

  module JsonFormat # :nodoc:
    extend self

    def extension
      "json"
    end

    def mime_type
      "application/json"
    end

    def encode(hash)
      hash.to_json
    end

    def decode(json)
      h = ActiveSupport::JSON.decode(json)
      h.values.flatten # Return type must be an array of hashes
    end
  end

  # GeoNames REST services base class
  class GeonamesResource < ActiveResource::Base
    self.site = "http://api.geonames.org/"
  end

  class Hierarchy < GeonamesResource
    # Hierarchy search
    def self.collection_path(prefix_options = {}, query_options = nil)
      super(prefix_options, query_options).gsub(/\.json|\.xml/, "")
    end

    def self.instantiate_collection(collection, prefix_options = {})
      puts collection.inspect
      col = super(collection,prefix_options)
      geoname_id_tree=[]
      geoname_tree=[]
      col.each {|item|
        geoname_id_tree<< item.geonameId
        geoname_tree<< item.name
      }
      return geoname_id_tree.join(','),geoname_tree.join(';')
    end

    def self.hierarchy(geoname_id, options = {:username => 'banu'})
      self.find(:all, :from => "/hierarchyJSON", :params => { :geonameId => geoname_id }.merge(options))
    end
  end


  # GeoNames Search REST services
  class Search < GeonamesResource
    # place search
    #
    # http://www.geonames.org/export/web-services.html#postalCodeSearch
    #
    self.element_name = "searchJSON"
    self.collection_name = "searchJSON"

    def self.collection_path(prefix_options = {}, query_options = nil)
      super(prefix_options, query_options).gsub(/\.json|\.xml/, "")
    end

    def self.instantiate_collection(collection, prefix_options = {})
      col = super(collection["geonames"],prefix_options)
      col.map! {|item|  {
         label: item.name+ (item.adminName1 ? ", " + item.adminName1 : "")+", " + item.countryName, value:"#{item.geonameId}"}
      }
      return col
    end
    def self.search(term, options = {:maxRows => 10,:userame => 'banu'})
      #self.find(:all, :from => "/searchJSON", :params => { :q => term }.merge(options))
      return self.find(:all, :params => { :q =>term, :username=>"cam156", :maxRows=>10})
    end
  end

end