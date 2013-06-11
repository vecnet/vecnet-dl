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
    #return unless self.where(name: name).empty?
    #authority = self.create(name: name)
    SubjectMeshEntry.transaction{
      sources.each do |uri|
      open(uri) do |f|
        mesh = MeshDataParser.new(f)
          mesh.each_mesh_record do |record|
            record_id= record['UI'].first
            begin
              SubjectMeshEntry.create!(:subject_mesh_term_id => record_id,
                                     :term => MeshDataParser.get_term(record),
                                     :subject_description=>MeshDataParser.get_description(record)
                                    )
              import_synonyms(record,record_id)
              import_trees(record,record_id)
            rescue Exception => e
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    }
  end

  def self.import_synonyms(record, mesh_id)
    items = []
    MeshDataParser.get_synonyms(record).each do |term|
     SubjectMeshSynonym.create!( :subject_synonym => term,
                                 :subject_mesh_term_id => mesh_id
                               )

    end
  end

  def self.import_trees(record, mesh_id)
    items = []
    MeshDataParser.get_tree(record).each do |tree|
      MeshTreeStructure.create!( :tree_structure => tree,
                                 :subject_mesh_term_id => mesh_id
                               )

    end
  end
end
