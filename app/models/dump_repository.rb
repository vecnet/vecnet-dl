class DumpRepository
  # TODO: make a rake task to run this code
  def run(filename=nil)
    # not the best way to do this since find will load a representation of
    # EVERY object in the repository into memory at once. There almost
    # certainly is a better way.
    result = GenericFile.find(:all).map do |obj|
      "#{obj.noid},#{obj.create_date},#{obj.modified_date},#{obj.mime_type},#{obj.content.size},#{obj.edit_users.first},#{obj.label}"
    end
    if filename
      File.open(filename, 'w') do |f|
        f.write "noid,create_date,modified_date,mime_type,content_size,edit_user,label\n"
        f.write(result.join("\n"))
      end
    end
    result
  end
end
