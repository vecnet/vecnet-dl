require 'libcdb-ruby'
require 'csv'
require 'json'

class AdminMapping
  attr_accessor :table

  def initialize
    @table = {}
  end

  # Find the geoid of the parent of this record.
  # returns either a geoid or nil
  def find_parent(r)
    p_id = nil
    fcode = r.fcode
    if fcode == "ADM4" || fcode == "ADM4H"
      code = "#{r.cc}+#{r.admin1}+#{r.admin2}+#{r.admin3}+"
    elsif fcode == "ADM3" || fcode == "ADM3H"
      code = "#{r.cc}+#{r.admin1}+#{r.admin2}++"
    elsif fcode == "ADM2" || fcode == "ADM2H"
      code = "#{r.cc}+#{r.admin1}+++"
    elsif fcode == "ADM1" || fcode == "ADM1H"
      code = "#{r.cc}+00+++"
    else
      code = "#{r.cc}+#{r.admin1}+#{r.admin2}+#{r.admin3}+#{r.admin4}"
    end
    p_id = @table[code]
    p_id = nil if p_id == r.id  # item is not parent of itself
    if p_id.nil? && r.fcode != "PCLI" && r.fcode != "PCLD"
      # last resort, try to put the item under its country...
      code = "#{r.cc}+00+++"
      p_id = @table[code]
      p_id = nil if p_id == r.id  # item is not parent of itself
    end
    p_id
  end

  def add(r)
    code = "#{r.cc}+#{r.admin1}+#{r.admin2}+#{r.admin3}+#{r.admin4}"
    @table[code] = r.id
  end

  def is_admin?(fcode)
    (fcode.start_with?("ADM") && fcode != "ADMD") ||
        fcode == "PCL" ||
        fcode == "PCLI" ||
        fcode == "PCLD" ||
        fcode == "PCLS" ||
        fcode == "CONT"
  end
end

# Generate the admin hierarchy for an array of records
# Moves records from ar to processed as they are converted.
# adm_deocde is a mapping from (country code, adm1) to geoid used to
# undo the FIPS encoding used for admin1 level.
# geoid is the id of the record to process.
# Any parent records are processed of the given record are processed as
# a side-effect
def process_admin(geoid, record_hash, admin_h)
  # already been processed?
  r = record_hash[geoid]
  return r if r.nil? || !r.parents.nil?

  pp = admin_h.find_parent(r)
  parent = process_admin(pp, record_hash, admin_h)

  if parent.nil?
    puts "No parent for #{r.id}, #{r.name}"
    r.parents = []
  else
    r.parents = parent.parents + [parent.id]
  end
  r
end

# like process_admin, but much simpler since we assume all possible parents
# have been processed and are in the admin hash
def process_other(r, admin_hash, admin_h)
  pp = admin_h.find_parent(r)
  parent = admin_hash[pp]
  if parent.nil?
    puts "No parent for #{r.id}, #{r.name}"
    r.parents = []
  else
    r.parents = parent.parents + [parent.id]
  end
  r
end

class Record
  attr_accessor :id, :name, :name_ascii, :lat, :long, :fclass, :fcode, :cc,
                :cc2, :admin1, :admin2, :admin3, :admin4, :moddate, :parents

  def to_s
    ascii = @name == @name_ascii ? nil : @name_ascii
    "#{@id}\t#{@name}\t#{ascii}\t#{@lat}\t#{@long}\t#{@fclass}\t#{@fcode}\t#{@cc}\t#{@cc2}\t#{@admin1}\t#{@admin2}\t#{@admin3}\t#{@admin4}\t#{@moddate}\t#{@parents.join("|")}"
  end

  def self.from_line(line)
    r = Record.new
    r.id          = line[0]
    r.name        = line[1]
    r.id          = line[0]
    r.name        = line[1]
    r.name_ascii  = line[2]
    r.lat         = line[4]
    r.long        = line[5]
    r.fclass      = line[6]
    r.fcode       = line[7]
    r.cc          = line[8]
    r.cc2         = line[9]
    r.admin1      = line[10]
    r.admin2      = line[11]
    r.admin3      = line[12]
    r.admin4      = line[13]
    r.moddate     = line[18]
    r
  end
end

def parse_tsv(source_file, output_base)
  # we do two passes. On the first pass we build an admin lookup table
  # On the second pass we filter the undesirable records and assign
  # the rest to hierarchy
  admin_h = AdminMapping.new
  admin_records = {}
  puts "First pass #{source_file}"
  # the dump files do not use quoting, so set the quote character to something
  # that can never appear.
  CSV.foreach(source_file, quote_char: "\x00", col_sep: "\t") do |line|
    # we only care about extracting the administration entries
    next unless line[6] == 'A' || line[6] == 'L'
    fcode = line[7]
    next if fcode.nil?
    if admin_h.is_admin?(fcode)
      r = Record.from_line(line)
      admin_records[line[0]] = r
      admin_h.add(r)
    end
  end

  puts "Extract Hierarchy"

  admin_records.each do |geoid, rec|
    process_admin(geoid, admin_records, admin_h)
  end

  puts "Second pass #{source_file}"
  puts "Save to #{output_base}.cdb"

  #LibCDB::CDB.open(output_base + '.cdb', 'w') do |db|
  File.open(output_base + '.txt', 'w') do |f|
    CSV.foreach(source_file, quote_char: "\x00", col_sep: "\t") do |line|
      # skip some feature classes for buildings and undersea things
      next if line[6] == 'S' || line[6] == 'U'

      r = admin_records[line[0]]
      if r.nil?
        record = Record.from_line(line)
        r = process_other(record, admin_records, admin_h)
      end

      #db[r.id] = r.to_s
      f.write(r.to_s)
      f.write("\n")
    end
  end


  puts "Save #{output_base}-admin.cdb"

  LibCDB::CDB.open(output_base + '-admin.cdb', 'w') do |db|
    admin_h.table.each do |code, id|
      db[code] = id
    end
  end
end

parse_tsv(ARGV[1], ARGV[2])
