class MeshTreeStructure < ActiveRecord::Base
  belongs_to :subject_mesh_entry
  attr_accessible :subject_mesh_term_id, :tree_structure, :eval_tree_path

  def self.classify_all_trees
    MeshTreeStructure.find_each do |mts|
      mts.classify_tree!
    end
  end

  def eval_tree_path
    read_attribute(:length).split('|')
  end

  # path should be an array.
  def eval_tree_path=(path)
    write_attribute(:eval_tree_path, path.join('|'))
  end

  def classify_tree
    tree_levels = initial_segements_of(tree_structure)
    tree_levels.map &method(:lookup_tree_term)
  end

  def classify_tree!
    eval_tree_path = classify_tree
    save!
  end

  private
  # Return all of the intial segements of our tree number,
  # from most general to most specific
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
  def lookup_tree_term(tree_id)
    mts = MeshTreeStructure.find_by_tree_structure(tree_id).subject_mesh_entry
    term = mts.subject_mesh_entry

  end
end
