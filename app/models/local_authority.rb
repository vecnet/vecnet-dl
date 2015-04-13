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
              import_print_synonyms(record,record_id)
              import_synonyms(record,record_id)
              import_trees(record,record_id)
            rescue Exception => e
              puts e.inspect
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    }
  end

  def self.harvest_more_mesh_print_synonyms(name, sources, opts = {})
    #return unless self.where(name: name).empty?
    #authority = self.create(name: name)
      sources.each do |uri|
        open(uri) do |f|
          mesh = MeshDataParser.new(f)
          mesh.each_mesh_record do |record|
            record_id= record['UI'].first
            begin
              puts "Begin transaction"
              import_print_synonyms(record,record_id)
            rescue Exception => e
              puts e.inspect
              raise ActiveRecord::Rollback
            end
          end
        end
      end
  end

  def self.mesh_print_synonyms(name, sources, opts = {})
    #return unless self.where(name: name).empty?
    #authority = self.create(name: name)
    sources.each do |uri|
      open(uri) do |f|
        mesh = MeshDataParser.new(f)
        mesh.each_mesh_record do |record|
          puts record['UI'].first
          MeshDataParser.get_print_synonyms(record)
        end
      end
    end
  end

  def self.import_synonyms(record, mesh_id)
     MeshDataParser.get_synonyms(record).each do |term|
     SubjectMeshSynonym.create!( :subject_synonym => term,
                                 :subject_mesh_term_id => mesh_id
                               )
    end
  end

  def self.import_print_synonyms(record, mesh_id)
    MeshDataParser.get_print_synonyms(record).each do |term|
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

  def self.entries_by_subject_mesh_term(query)
    return [] if query.empty?
    sql = SubjectMeshEntry.where("lower(term) like ?", "#{query.downcase}%").select("term, subject_mesh_term_id").limit(25).to_sql
    SubjectMeshEntry.find_by_sql(sql).map do |hit|
      {:uri => hit.subject_mesh_term_id, :label => hit.term}
    end
  end

  def self.entries_by_species(query)
    return [] if query.empty?
    term_types = ["species", "species group", "species subgroup", "subspecies"]
    sql = NcbiSpeciesTerm.where("term_type in (?) and lower(term) like ?", term_types, "#{query.downcase}%").select("term, species_taxon_id").limit(25).to_sql
    NcbiSpeciesTerm.find_by_sql(sql).map do |hit|
      {:uri => hit.species_taxon_id, :label => hit.term}
    end
  end
end
