
def tree_number(taxons, id)
  t = taxons[id]
  return "" if t.nil?
  return id if t[:parentid] == id
  tn = t[:tree_number]
  return tn unless tn.nil?
  tn = "#{tree_number(taxons, t[:parentid])}.#{id}"
  t[:tree_number] = tn
end

def output_tree_numbers(source_filename)
  File.open(source_filename) do |f|
    taxons = {}
    f.each do |line|
      fields = line.split("\t|\t")
      taxonid = fields[0]
      parentid = fields[1]
      level = fields[2]
      taxons[taxonid] = {parentid: parentid, level: level}
    end
    taxons.keys.each do |taxonid|
      tree_number(taxons, taxonid)
      t = taxons[taxonid]
      puts "#{taxonid}|#{t[:level]}|#{t[:tree_number]}"
    end
  end
end

output_tree_numbers("nodes.dmp")
