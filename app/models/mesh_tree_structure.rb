class MeshTreeStructure < ActiveRecord::Base
  belongs_to :subject_mesh_entry
  attr_accessible :subject_mesh_term_id, :tree_structure, :eval_tree_path

  def self.classify_all_trees
  end

  def classify_tree
    tree_levels = initial_segements_of(tree_structure)
    facet = ''
    if tree_levels.count < 3
      facet = lookup_tree(tree_levels.last)
    else
      terms = tree_levels[2..-1].map &method(:lookup_tree)
      facets = []
      terms_so_far = ''
      terms.each_with_index do |term, index|
        terms_so_far << term
        facets << "#{index}|#{terms_so_far}"
        terms_so_far << "|"
      end
    end
  end

  private
  # Return all of the intial segements of our tree number
  # e.g. 'D03.456.23.789' returns ['D03', 'D03.456', 'D03.456.23', 'D03.456.23.789']
  def initial_segements_of(s)
    result = []
    loop do
      result << s
      s = s.rpartition('.').first
      break if s.empty?
    end
    result.reverse
  end

  # given a tree id, return the main subject term
  # e.g. 'C03.752.530' returns 'Malaria'
  def lookup_tree(tree_id)
    mts = MeshTreeStructure.find_by_tree_structure(tree_id).subject_mesh_entry
    term = mts.subject_mesh_entry

  end
end
