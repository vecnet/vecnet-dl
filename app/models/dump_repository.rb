class DumpRepository
  def self.run_to_file(filename)
    File.open(filename, "w") do |f|
      self.run(f)
    end
  end

  # f is a FILE or output stream which accepts the method :write
  def self.run(f)
    f.write "noid,model,create_date,modified_date,mime_type,content_size,edit_user,label\n"

    [Citation, GenericFile, CitationFile, Collection].each do |model|
      model_name = model.to_s
      model.find_each(:all) do |obj|
        mime_type = self.try_attribute(obj, :mime_type)
        content_size = self.try_attribute(self.try_attribute(obj, :content), :size)
        f.write "#{obj.noid},#{model_name},#{obj.create_date},#{obj.modified_date},#{mime_type},#{content_size},#{obj.edit_users.first},\"#{obj.title}\"\n"
      end
    end
  end

  def self.try_attribute(obj, name)
    obj.send(name)
  rescue NoMethodError
    nil
  end
end
