class RepositoryComber

  # go through every repository object and update the statistics kept
  # in our database
  def self.update_dabatase
    ActiveFedora::Base.find_each do |obj|
      record = ItemRecords.find_or_create(obj.pid)
      record.ingest_date = obj.create_date
      record.modified_date = obj.modified_date

      cobj = obj.adapt_to_cmodel
      record.af_model = cobj.class.to_s
      record.owner = cobj.depositor
      record.
    end

    end
  end
end
