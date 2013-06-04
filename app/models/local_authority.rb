# from scholarsphere
# not sure how it works in vecnet

class LocalAuthority < ActiveRecord::Base

  def self.harvest_mesh_ascii(name, sources, opts = {})
    return unless self.where(name: name).empty?
    authority = self.create(name: name)
    entries = []
    sources.each do |uri|
      open(uri) do |f|
        mesh = MeshDataParser.new(f)
        mesh.each_mesh_record do |record|
          record['MH'].each do |label|
            entries << SubjectLocalAuthorityEntry.new(:label => label,
                                                      :lower_label => label.downcase,
                                                      :uri => record['UI'].first)
          end
        end
      end
    end
    SubjectLocalAuthorityEntry.import entries
  end
end
