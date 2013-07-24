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

  def self.entries_by_subject_mesh_term(model, term, query)
    return if query.empty?
    lowQuery = query.downcase
    hits = []
    logger.debug("Find by term: #{term.inspect}, model:#{model.inspect}")
    puts"Find by term: #{term.inspect}, model:#{model.inspect}"
# move lc_subject into it's own table since being part of the usual structure caused it to be too slow.
# When/if we move to having multiple dictionaries for subject we will need to also do a check for the appropriate dictionary.
    if (term == 'subject' && model == 'generic_files') # and local_authoritiy = lc_subject
      logger.debug("Matched subject")
      sql = SubjectMeshEntry.where("lower(term) like ?", "#{lowQuery}%").select("term, subject_mesh_term_id").limit(25).to_sql
      SubjectMeshEntry.find_by_sql(sql).each do |hit|
        hits << {:uri => hit.subject_mesh_term_id, :label => hit.term}
      end
    else
      logger.debug("Else part --------- Find by term: #{term.inspect}, model:#{model.inspect}")
      puts "---------ERROR-------"
      dterm = DomainTerm.where(:model => model, :term => term).first
      if dterm
        authorities = dterm.local_authorities.collect(&:id).uniq
        sql = LocalAuthorityEntry.where("local_authority_id in (?)", authorities).where("lower(label) like ?", "#{lowQuery}%").select("label, uri").limit(25).to_sql
        LocalAuthorityEntry.find_by_sql(sql).each do |hit|
          hits << {:uri => hit.uri, :label => hit.label}
        end
      end
    end
    return hits
  end
end
