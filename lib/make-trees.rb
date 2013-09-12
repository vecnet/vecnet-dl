# translate the geonames hierarchy.txt file into
# a file giving the tree number for each entity
class Tree
  # hash with
  # keys == geonames feature ids
  # value == list of parent geoname ids
  attr_accessor :nodes

  def initialize
    self.nodes = {}
  end

  def load_from_file(fname)
    File.open(fname) do |f|
      f.each_line do |line|
        parent, child = line.split("\t")
        insert_tuple(parent, child)
      end
    end
  end

  def insert_tuple(parent, child)
    self.nodes[child] = (self.nodes.fetch(child, []) + [parent]).uniq
  end

  # given a geoname id
  # return a list of "tree numbers" (i.e. strings of the form "grandparent.parent.id")
  def tree_numbers(id)
    parents = self.nodes[id]
    if parents.nil?
      return ["#{id}"]
    else
      parent_trees = parents.map { |p| tree_numbers(p) }.flatten
      parent_trees.map { |tn| "#{tn}.#{id}" }
    end
  end

  # TODO: maybe change this to take a stream to write to?
  def print_to_file
    #f = File.new("#{Dir.pwd}/tmp/geoname_tree.txt", "wb")
    File.open("geoname_tree.txt", 'w') do |f|
      nodes.keys.each do |id|
        ts = tree_numbers(id).join("|")
        f.write("#{id}|#{ts}")
        f.write("\n")
        puts "#{id}|#{ts}"
      end
    end
  end
end

# TODO: split this out into a rake task
tree = Tree.new
tree.load_from_file("/Users/blakshmi/projects/Geonames_data/hierarchy.txt")
tree.print_to_file
