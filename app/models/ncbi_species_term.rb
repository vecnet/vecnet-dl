class NcbiSpeciesTerm < ActiveRecord::Base
  self.table_name = 'species_taxon_entries'

  attr_accessible :species_taxon_id, :subject_description,:term, :term_synonyms,  :term_type,
                  :full_tree_id,  :facet_tree_id, :facet_tree_term

  serialize :term_synonyms
  serialize :facet_tree_term

  def facet_tree_term
    trees = read_attribute(:facet_tree_term)
    if trees.nil?
      []
    else
      trees.split("|")
    end
  end

  def self.get_term_info(term)
    terms = get_species_term([term])
    return {} if terms.empty? || terms.length > 1
    t = terms.first
    {
      id: t.species_taxon_id,
      term: t.term,
      hierarchy: t.get_solr_hierarchy_from_tree.flatten,
    }
  end

  def self.get_species_term(terms)
    #ignore case
    term_types=["species", "species group", "species subgroup", "subspecies"]
    NcbiSpeciesTerm.where("term_type in (?) and lower(term) in ( ?)", term_types, terms.collect{|term|term.downcase}).all
  end

  def self.get_species_faceting(terms)
    ncbi_species = self.get_species_term(terms)
    all_trees = ncbi_species.map do |s|
      s.get_solr_hierarchy_from_tree.flatten
    end
    all_trees.flatten
  end


  def self.load_from_tree_file(tree_filename)
    entries = []
    count = 0
    File.open(tree_filename) do |f|
      f.each do |line|
        fields = line.strip.split('|')
        entries << NcbiSpeciesTerm.new(species_taxon_id: fields[0],
                                        term: fields[1],
                                        term_type: fields[2],
                                        full_tree_id: fields[3]
                                       )
        count += 1
        if (count % 10000) == 0
          print "importing #{count - 9999}--#{count}."
          NcbiSpeciesTerm.import entries
          print ".\n"
          entries = []
        end
      end
    end
    print "importing #{count}."
    NcbiSpeciesTerm.import [:species_taxon_id, :term, :term_type, :full_tree_id], entries
  end

  # the block sets parameters on `tt` describing which subtrees we want
  # to keep, which to prune, and which levels to collapse
  def self.generate_facet_treenumbers(&block)
    tt = TreeTransform.new
    yield tt
    # only give facets to species terms
    NcbiSpeciesTerm.where(term_type: ["species", "species group", "species subgroup", "subspecies"]).find_each do |term|
      ft_id = tt.transform(term.full_tree_id)
      if term.facet_tree_id != ft_id
        print "#{term.species_taxon_id} (#{term.term_type}) #{term.full_tree_id} -> #{ft_id} .\n"
        term.facet_tree_id = ft_id
        term.facet_tree_term = terms_for_treenumber(ft_id)
        term.save
      end
    end
  end

  def self.terms_for_treenumber(tree_number)
    return "" if tree_number.nil?
    elements = tree_number.split(".")
    taxons = NcbiSpeciesTerm.where(species_taxon_id: elements).all
    result = elements.map do |tn|
      taxons.find { |x| x.species_taxon_id == tn }.term
    end
    result.join("|")
  end

  def get_solr_hierarchy_from_tree
    tree_to_solrize = facet_tree_term
    hierarchies = tree_to_solrize.each_with_index.map do |_, i|
      tree_to_solrize[0..i].join(':')
    end
    hierarchies
  end

  class TreeTransform
    def initialize
      @subtrees = []
      @remove_nodes = []
      @remove_ranks = []
      @prune_nodes = []
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
      terms = NcbiSpeciesTerm.where(species_taxon_id: taxid_list)
      taxid_list.map do |taxid|
        terms.find { |x| x.species_taxon_id == taxid }.term_type
      end
    end
  end
end
