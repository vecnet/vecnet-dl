class MeshTreeStructure < ActiveRecord::Base
  belongs_to :subject_mesh_entry , :foreign_key => "subject_mesh_term_id"
  attr_accessible :subject_mesh_term_id, :tree_structure, :eval_tree_path

  serialize :eval_tree_path

  def self.get_term(mesh_tree)
    SubjectMeshEntry.where(:subject_mesh_term_id=> 
                                            MeshTreeStructure.where('mesh_tree_structures.tree_structure' => mesh_tree).map(&:subject_mesh_term_id)
                                          )
  end

  def self.classify_all_trees
    MeshTreeStructure.find_each do |mts|
      mts.classify_tree!
    end
  end

  def eval_tree_path
    trees = read_attribute(:eval_tree_path) || write_attribute(:eval_tree_path, "")
    if trees 
      trees.split("|")
    else
      []
    end
  end

  # path should be an array.
  # def eval_tree_path=(path)
  #   raise "Path to Join #{path.inspect}"
  #   unless path.empty?
  #     tree_path=path.join('|')
  #     puts "After Join #{tree_path.inspect}"
  #     write_attribute(:eval_tree_path, tree_path)
  #   else
  #     write_attribute(:eval_tree_path, "")
  #   end
  # end

  def classify_tree
    tree_levels = initial_segements_of(tree_structure)
    tree_array=tree_levels.map &method(:lookup_tree_term)
    #eval_tree_path=(tree_array)
    return tree_array
  end

  def classify_tree!
    return if classify_tree.empty?
    tree_path = classify_tree.join('|')
    update_attribute(:eval_tree_path, tree_path)
  end

  def get_solr_hierarchy_from_tree
    tree_to_solrize = eval_tree_path
    # if tree is too deep, just use the tail
    tree_to_solrize = tree_to_solrize[2..-1] if tree_to_solrize.count > 3
    hierarchies = tree_to_solrize.each_with_index.map do |_, i|
      tree_to_solrize[0..i].join(':')
    end
    hierarchies
  end

  #private
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
    return self.class.get_term(tree_id).first.term
  end
end
