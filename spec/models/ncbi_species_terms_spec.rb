require 'spec_helper'
require 'stringio'

describe "NCBI species terms" do
  it "imports from a file" do
    source = <<EOS
1|root|no rank|
2|Bacteria|superkingdom|1.131567.2
6|Azorhizobium|genus|1.131567.2.1224.28211.356.335928.6
7|Azorhizobium caulinodans|species|1.131567.2.1224.28211.356.335928.6.7
9|Buchnera aphidicola|species|1.131567.2.1224.1236.91347.543.32199.9
10|Cellvibrio|genus|1.131567.2.1224.1236.72274.135621.10
11|[Cellvibrio] gilvus|species|1.131567.2.201174.1760.85003.2037.85006.85016.1707.11
13|Dictyoglomus|genus|1.131567.2.68297.203486.203487.203488.13
14|Dictyoglomus thermophilum|species|1.131567.2.68297.203486.203487.203488.13.14
16|Methylophilus|genus|1.131567.2.1224.28216.206350.32011.16
EOS
    File.stub(:open).with("dummy").and_yield(StringIO.new(source))
    NcbiSpeciesTerms.load_from_tree_file("dummy")
    t = NcbiSpeciesTerms.find("10")
    t.species_taxon_id.should == "10"
    t.term.should == "Cellvibrio"
    t.term_type.should == "genus"
    t.full_tree_id.should == "1.131567.2.1224.1236.72274.135621.10"
  end
end
