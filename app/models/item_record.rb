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
    ir = ItemRecord.where(pid: pid).first
    ir = ItemRecord.new(pid: pid) if ir.nil?
    ir
  end
end
