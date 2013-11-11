class NcbiSpeciesTerms < ActiveRecord::Base
  self.table_name = 'species_taxon_entries'

  attr_accessible :species_taxon_id, :subject_description,:term, :term_synonyms,  :term_type,
                  :full_tree_id,  :facet_tree_id, :facet_tree_term

  serialize :term_synonyms

  self.primary_key = 'species_taxon_id'


  def self.load_from_tree_file(tree_filename)
    entries = []
    File.open(tree_filename) do |f|
      f.each do |line|
        fields = line.strip.split('|')
        entries << NcbiSpeciesTerms.new(species_taxon_id: fields[0],
                                        term: fields[1],
                                        term_type: fields[2],
                                        full_tree_id: fields[3]
                                       )
      end
    end
    NcbiSpeciesTerms.import entries
  end

  def self.generate_facet_treenumbers(&block)
    xform = TreeTransform.new
    yield xform
    NcbiSpeciesTerms.each do |term|
      facet_tree = nil
      if ["species"].include? term.rank
        facet_tree = xform(term.full_tree_id)
      end
      term.facet_tree = facet_tree
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
          break
        end
      end
      return nil unless ok

      # is this not in a pruned subtree?
      @prune_nodes.each do |taxid|
        return nil if elements.include? taxid
      end
      
      # does this contain any nodes to be removed?
      @remove_nodes.each do |taxid|
        elements.delete(taxid)
      end

      ranks = get_ranks(elements)

      @remove_ranks.each do |rank|
        loop do
          i = ranks.index(rank)
          break if i.nil?
          ranks.delete_at(i)
          elements.delete_at(i)
        end
      end

      # done!
      elements.join(".")
    end

    private
    def get_ranks(taxid_list)
      taxid_list.map do |taxid|
        r = @rank_cache[taxid]
        if r.nil?
          term = NcbiSpeciesTerms.find(taxid)
          r = term.term_type unless term.nil?
        end
        r
      end
    end
  end
end
