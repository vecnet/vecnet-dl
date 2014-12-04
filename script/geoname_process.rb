
require 'libcdb-ruby'
require 'csv'
require 'json'

def source_file
  #"data/KE.txt"
  "data/1000000Countries.txt"
end
def output_base
  ",,1m"
end

# first pass: parse file and create a (cc,admin1) -> geoid mapping
# second pass: generate all auxiliary data
#    - hierarchy name
#    - prefix lookup table
#    - solr indexing fields

# TODO: try not to hold everything in memory at once



# Generate the admin hierarchy for an array of records
# Moves records from ar to new_records as they are converted.
# adm_deocde is a mapping from (country code, adm1) to geoid used to
# undo the FIPS encoding used for admin1 level.
# geoid is the id of the record to process.
# Any parent records are processed of the given record are processed as
# a side-effect
def process_record(ar, new_records, adm_decode, geoid)
  r = new_records[geoid]
  return r unless r.nil?  # already been processed?
  r = ar[geoid]
  return nil if r.nil?    # there was never a record with this id

  # remove entry to prevent cycles
  ar.delete(geoid)

  # try to resolve the immediate parent. Depends on which items
  # have values. Plus funkyness to handle admin1 fields containing FIPS codes
  # and not geoids.
  pp = nil
  fcode = r[:fcode]
  if fcode == "ADM4" || fcode == "ADM4H"
    code = "#{r[:cc]}+#{r[:admin1]}+#{r[:admin2]}+#{r[:admin3]}+"
  elsif fcode == "ADM3" || fcode == "ADM3H"
    code = "#{r[:cc]}+#{r[:admin1]}+#{r[:admin2]}++"
  elsif fcode == "ADM2" || fcode == "ADM2H"
    code = "#{r[:cc]}+#{r[:admin1]}+++"
  elsif fcode == "ADM1" || fcode == "ADM1H"
    code = "#{r[:cc]}+00+++"
  else
    code = "#{r[:cc]}+#{r[:admin1]}+#{r[:admin2]}+#{r[:admin3]}+#{r[:admin4]}"
  end
  pp = adm_decode[code]
  pp = nil if pp == r[:id]  # item is not parent of itself
  if pp.nil? && r[:fcode] != "PCLI" && r[:fcode] != "PCLD"
    # last resort, try to put the item under its country...
    code = "#{r[:cc]}+00+++"
    pp = adm_decode[code]
  end

  parent = process_record(ar, new_records, adm_decode, pp)

  if parent.nil?
    r[:parents] = []
  else
    r[:parents] = parent[:parents] + [parent[:id]]
  end
  new_records[geoid] = r
  r
end

# name list has the form
class Pair
  attr_accessor :name, :value, :score
  def initialize(name, value, score)
    @name = name
    @value = value
    @score = score
  end
end

# given a list of Pairs, will produce a list of all prefixes of the given names
# Calls a given block with (k,v) where k is the prefix, and v is a list of
# 10 Pairs matching that previx.
def make_lists(name_list, level=0, query="", &block)
  name_list.sort_by! {|n| [n.score, n.name]}
  first_ten = name_list.first(10)
  tree = name_list.group_by { |n| n.name[level] }
  name_list = nil
  tree.each do |letter,values|
    next if letter.nil?
    if values.length == 1
      # This is a single word.
      yield query + letter, [values.first.value]
      # Also add all intermediate prefixes for this word
      #word = values.first.name
      #list = [values.first.value]
      #i = query.length
      #while i < word.length
      #  yield word[0..i], list
      #  i += 1
      #end
    else
      make_lists(values, level+1, query + letter, &block)
    end
    tree.delete(letter)
  end
  list = tree[nil]
  tree.delete(nil)
  list = [] if list.nil?
  if list.length < 10
    list += first_ten
    list = list.uniq.first(10)
  end
  yield query, list.map { |pair| pair.value }
end

def create_pair(record)
  # lower scores are better
  score = 40
  score -= 10 if record[:fclass] == "A"
  score -= 10 if record[:fclass] == "P"
  score -= 20 if record[:fcode] == "PCLI" || record[:fcode] == "PCLD"
  Pair.new((record[:name_ascii] || record[:name]).downcase,
           record[:id],
           score)
end

def parse_tsv
  all_records = {}
  adm_decode = {}
  puts "Read #{source_file}"
  CSV.foreach(source_file, quote_char: "\x00", col_sep: "\t") do |line|
    # skip some feature classes for buildings and undersea things
    next if line[6] == 'S' || line[6] == 'U'

    id = line[0]
    fcode = line[7]
    cc = line[8]
    all_records[id] = {
      id:       line[0],
      name:     line[1],
      name_ascii: line[2],
      lat:      line[4],
      long:     line[5],
      fclass:   line[6],
      fcode:    line[7],
      cc:       line[8],
      cc2:      line[9],
      admin1:   line[10],
      admin2:   line[11],
      admin3:   line[12],
      admin4:   line[13],
      moddate:  line[18]
    }

    next if fcode.nil?
    if (fcode.start_with?("ADM") && fcode != "ADMD") ||
        fcode == "PCLI" ||
        fcode == "PCLD"
      code = "#{line[8]}+#{line[10]}+#{line[11]}+#{line[12]}+#{line[13]}"
      adm_decode[code] = id
    end
  end

  puts "Extract Hierarchy"

  new_records = {}
  all_records.each do |geoid, rec|
    process_record(all_records, new_records, adm_decode, geoid)
  end

  puts "Save #{output_base}.cdb"

  LibCDB::CDB.open(output_base + '.cdb', 'w') do |db|
    new_records.each do |id, v|
      db[id] = JSON.fast_generate(v)
      db["@" + v[:name]] = id
    end
  end

  names = new_records.map { |_,r| create_pair(r) }
  new_records = nil

  puts "Save #{output_base}-typeahead.cdb"

  LibCDB::CDB.open(output_base + '-typeahead.cdb', 'w') do |db|
    make_lists(names) do |s, v|
      db[s] = v
    end
  end
end

parse_tsv
