class CitationMetadataIngestService

  attr_accessor :metadata_file, :curation_concern, :citations

  class CitationData
    attr_accessor :metadata_file, :curation_concern, :metadata_hash
    def initialize(hash)
      @metadata_hash=hash
      hash.each do |k,v|
        self.instance_variable_set("@#{k}", v)  ## create and initialize an instance variable for this key/value pair
        self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## create the getter that returns the instance variable
        self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})  ## create the setter that sets the instance variable
      end
    end

    def places
      return [] if place.nil?
      return place.split("|").map{|t|t.strip}
    end

    def countries
      return [] if country.nil?
      return country.split("|").map{|t|t.strip}
    end

    def subjects
      return [] if subject.nil?
      return subject.split("|").map{|t|t.strip}
    end

    def keywords
      return [] if keyword.nil?
      return keyword.split("|").delete_if{|name| name.to_s.strip.empty?}.map{|t|t.strip}
    end

    def locations
      countries.concat(places)
    end

    def geoname_locations
      geonames=locations.map{|location| LocationHierarchyServices.geoname_location_format(location)}
      puts "Geonames to update: #{geonames.inspect}"
      return geonames
    end

    def start_time
      [contentyear_start]
    end

    def end_time
      [contentyear_end]
    end

    def find_citation_by_pid
      return Citation.find(pid)
    end

    def extract_metadata
      metadata=
        {
          based_near: geoname_locations,
          subject: subjects,
          start_time:start_time,
          end_time:end_time,
          tag:keywords
        }
      puts "Metadata to update: #{metadata.inspect}"
      return metadata
    end

    def update_citation
      begin
        if curation_concern.nil?
          logger.error("Could not find citation with pid #{pid.inspect}, failed to update metadata #{self.to_s}")
        else
          actor.update!
          logger.info "Ingested Citation with id: @curation_concern.pid}"
          puts "Ingested Citation with id: #{@curation_concern.pid}"
        end
      rescue ActiveFedora::RecordInvalid=>e
        logger.error "Error occured during creation: #{e.inspect}"
      end
    end

    def curation_concern
      @curation_concern ||= find_citation_by_pid
    end

    def to_s
      return "Metadata to be updated: #{@metadata_hash.inspect}"
    end

    include Morphine
    register :actor do
      CurationConcern.actor(curation_concern, User.batchuser(), extract_metadata)
    end
  end

  def initialize(csv_file_with_metadata)
    @metadata_file = csv_file_with_metadata
    @citations=[]
    process_csv
  end

  def ingest_all
    citations.each do |c|
      c.update_citation
    end
  end

  def process_csv
    CSV.foreach(metadata_file, {:headers => true, :header_converters => :symbol}) do |row|
      hash_object=CitationData.new(row)
      @citations<<hash_object
    end
    logger.debug("Citations from csv: #{@citations.count}, First Citation: #{@citations.first.inspect}")
  end
end