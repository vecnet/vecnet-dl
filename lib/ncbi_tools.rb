
class NcbiTools
  def create_tree_file(node_dmp_filename, names_dmp_filename, out_filename)
    taxons = parse_nodes_file(node_dmp_filename)
    names = parse_names_file(names_dmp_filename)
    File.open(out_filename, "w") do |f|
      taxons.keys.each do |taxonid|
        tree_number(taxons, taxonid)
        t = taxons[taxonid]
        term = names[taxonid].first
        f.puts "#{taxonid}|#{term}|#{t[:level]}|#{t[:tree_number]}"
      end
    end
  end

  def create_synonym_file(names_dmp_filename, out_filename)
    names = parse_names_file(names_dmp_filename)
    File.open(out_filename, "w") do |f|
      names.each do |k, v|
        if v.nil?
          puts "@@@ #{k}, #{v}"
        end
        f.puts v.join("|")
      end
    end
  end

  private

  # given a map of taxonid to {parentid: , level:}
  # and a taxonid, return the tree number for that id.
  # (e.g. "1.34.2.654")
  def tree_number(taxons, id)
    t = taxons[id]
    return "" if t.nil?
    return id if t[:parentid] == id
    tn = t[:tree_number]
    return tn unless tn.nil?
    tn = "#{tree_number(taxons, t[:parentid])}.#{id}"
    t[:tree_number] = tn
  end

  # given a file object 'f'
  # return an map of taxonid to a list of names
  # the first name is the cacnonical "scientific name"
  # followed by any others.
  # strips names of types "authority", "type material", "includes", "in-part"
  def parse_names_file(fname)
    # this caching should be comparing the filename...
    return @names unless @names.nil?
    names = {}
    File.open(fname) do |f|
      # we exploit the fact that the file is sorted, so as soon as we see a different
      # taxonid, the old one is finished
      current_taxon_id = nil
      current_taxon_syn = []
      f.each do |line|
        fields = line.split(/\t\|[\t\n]/)
        taxonid = fields[0]
        term = fields[1]
        type = fields[3]
        next if ["authority", "type material", "includes", "in-part"].include?(type)
        if current_taxon_id != taxonid
          names[current_taxon_id] = current_taxon_syn unless current_taxon_id.nil?
          current_taxon_id = taxonid
          current_taxon_syn = []
        end
        # put scientific names at the beginning
        current_taxon_syn.insert(
          type == "scientific name" ? 0 : -1,
          term)
      end
      names[current_taxon_id] = current_taxon_syn unless current_taxon_id.nil?
    end
    @names = names
  end

  def parse_nodes_file(fname)
    taxons = {}
    File.open(fname) do |f|
      f.each do |line|
        fields = line.split("\t|\t")
        taxonid = fields[0]
        parentid = fields[1]
        level = fields[2]
        taxons[taxonid] = {parentid: parentid, level: level}
      end
    end
    return taxons
  end
end
