class NcbiSpeciesTerms < ActiveRecord::Base
  self.table_name = 'species_taxon_entries'

  attr_accessible :species_taxon_id, :subject_description,:term, :term_synonyms,  :term_type,
                  :full_tree_id,  :facet_tree_id, :facet_tree_term

  serialize :term_synonyms

  self.primary_key = 'species_taxon_id'


  def self.load_from_tree_file(tree_filename)
    entries = []
    count = 0
    File.open(tree_filename) do |f|
      f.each do |line|
        fields = line.strip.split('|')
        entries << fields[0..3]
        #entries << NcbiSpeciesTerms.new(species_taxon_id: fields[0],
        #                                term: fields[1],
        #                                term_type: fields[2],
        #                                full_tree_id: fields[3]
        #                               )
        count += 1
        if (count % 10000) == 0
          print "importing #{count - 999}--#{count}."
          NcbiSpeciesTerms.import [:species_taxon_id, :term, :term_type, :full_tree_id], entries
          print ".\n"
          entries = []
        end
      end
    end
    print "importing #{count}."
    NcbiSpeciesTerms.import [:species_taxon_id, :term, :term_type, :full_tree_id], entries
  end

  def self.generate_facet_treenumbers(&block)
    tt = TreeTransform.new
    yield tt
    NcbiSpeciesTerms.find_each do |term|
      facet_tree = nil
      # only give facets to species terms
      if ["species", "species group", "species subgroup", "subspecies"].include? term.term_type
        facet_tree = tt.transform(term.full_tree_id)
      end
      if term.facet_tree_id != facet_tree
        term.facet_tree = facet_tree
        term.save
      end
    end
  end


  class TreeTransform
    def initialize
      @subtrees = []
      @remove_nodes = []
      @remove_ranks = []
      @prune_nodes = []
      @rank_cache = {}
    end
    def subtree(taxid)
      @subtrees << taxid
    end
    def remove(taxid)
      @remove_nodes << taxid
    end
    def prune(taxid)
      @prune_nodes << taxid
    end
    def remove_rank(rank_name)
      @remove_ranks << rank_name
    end

    def transform(species_term)
      elements = species_term.split(".")

      # is this in a target subtree?
      ok = false
      @subtrees.each do |taxid|
        i = elements.index(taxid)
        unless i.nil?
          elements = elements[i..-1]
          ok = true
        end
      end
      return nil unless ok

      # is this not in a pruned subtree?
      @prune_nodes.each do |taxid|
        return nil if elements.include? taxid
      end

      # are there any nodes to be removed?
      @remove_nodes.each do |taxid|
        elements.delete(taxid)
      end

      # remove any nodes which have forbidden ranks
      if @remove_ranks.length > 0
        ranks = get_ranks(elements)

        @remove_ranks.each do |rank|
          loop do
            i = ranks.index(rank)
            break if i.nil?
            ranks.delete_at(i)
            elements.delete_at(i)
          end
        end
      end

      # done!
      return nil if elements.length == 0
      elements.join(".")
    end

    private
    def get_ranks(taxid_list)
      taxid_list.map do |taxid|
        r = @rank_cache[taxid]
        if r.nil?
          term = NcbiSpeciesTerms.find_by_species_taxon_id(taxid)
          @rank_cache[taxid] = r = term.term_type unless term.nil?
        end
        r
      end
    end
  end
end
