# Sync the fedora records for our items into the ItemRecord table in our
# database. This may take a while. We sync Citation, GenericFile, and
# CitationFile objects. We do not sync Batch or Collection objects.
class SyncItemRecords
  GOOD_CLASSES = [Citation, GenericFile, CitationFile].freeze

  def self.sync
    ActiveFedora::Base.find_each do |obj|
      next unless GOOD_CLASSES.include?(obj.class)
      r = ItemRecord.find_or_create(obj.noid)
      r.pid = obj.noid
      r.af_model = obj.class.to_s
      r.owner = obj.depositor
      r.bytes = obj.size
      r.mimetype = obj.file_format if obj.respond_to?(:file_format)
      r.parent = self.lookup_parent(obj)
      r.ingest_date = obj.date_uploaded
      r.record_mod_date = obj.date_modified
      r.access_rights = self.decode_access_rights(obj)
      r.resource_type = obj.resource_type.first
      r.save
    end
  end

  def self.decode_access_rights(obj)
    return "public" if obj.read_groups.contains?("public")
    return "vecnet" if obj.read_groups.contains?("registered")
    "private"
  end

  def self.lookup_parent(obj)
    return obj.batch.pid if obj.class == CitationFile
    id
  end
end
