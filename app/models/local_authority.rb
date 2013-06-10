require Sufia::Engine.root.join('app/models/local_authority.rb')

class LocalAuthority
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

  def self.harvest_more_mesh_ascii(name, sources, opts = {})
    return unless self.where(name: name).empty?
    authority = self.create(name: name)
    termEntries = []
    termTreeEntries=[]
    sources.each do |uri|
      open(uri) do |f|
        mesh = MeshDataParser.new(f)
        mesh.each_mesh_record do |record|
          record_id= record['UI'].first
          termEntries << SubjectMeshTermEntry.new(:label => MeshDataParser.get_label(record),
                                              :lower_label => MeshDataParser.get_label_downcase(record),
                                              :subject_mesh_term_id => record_id,
                                              :subject_synonyms=>MeshDataParser.get_synonyms(record),
                                              :subject_description=>MeshDataParser.get_description(record)
                                              )
          termTreeEntries << MeshTreeStructure.new( :subject_mesh_term_id => record_id,
                                                    :tree_structure=>MeshDataParser.get_tree(record)
          )
        end
      end
    end
    SubjectMeshTermEntry.import termEntries
    MeshTreeStructure.import termTreeEntries
  end
end
