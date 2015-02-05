class ItemRecord < ActiveRecord::Base
  attr_accessible :pid,
    :af_model,
    :owner,
    :bytes,
    :mimetype,
    :parent,
    :aggregation_key,
    :ingest_date,
    :access_rights

  def self.find_or_create(pid)
    result = ItemRecord.where(pid: pid).first
    result = ItemRecord.new(pid: pid) if result.nil?
    result
  end
end
