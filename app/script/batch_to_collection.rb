class BatchToCollection
  # Transform all Batch objects to Collection objects
  #
  # Used to migrate the Fedora data from scholarsphere data model
  # to the curate data model. Usage:
  #
  # On rails console type
  #
  # a = BatchToCollection.new
  # a.migrate
  #
  def migrate
    Batch.all.each do |batch|
      # Thanks to Adam Wead who prointed out this way of
      # changing fedora object models
      c = Collection.new(:pid => batch.pid)
      c.save
    end
  end
end
