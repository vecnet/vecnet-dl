require 'spec_helper'
require 'stringio'

describe "NCBI species term" do
  it "imports from a file" do
    source = <<EOS
1|root|no rank|1
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
    NcbiSpeciesTerm.load_from_tree_file("dummy")
    t = NcbiSpeciesTerms.find("10")
    t.species_taxon_id.should == "10"
    t.term.should == "Cellvibrio"
    t.term_type.should == "genus"
    t.full_tree_id.should == "1.131567.2.1224.1236.72274.135621.10"
  end

  describe "TreeTransform" do
    before(:each) do
      NcbiSpeciesTerms.import([:species_taxon_id, :term_type, :full_tree_id], [
        ["1", "genus", "1"],
        ["2", "no rank", "1.2"],
        ["3", "subgenus", "1.2.3"],
        ["4", "species", "1.2.3.4"],
        ["5", "species", "1.2.5"]
      ])
      @tt = NcbiSpeciesTerms::TreeTransform.new
      @tt.subtree("2")
    end
    it "handles subtree directive" do
      @tt.subtree("4")
      @tt.transform("1.2.3").should == "2.3"
      @tt.transform("1.3").should == nil
      @tt.transform("2.3.5").should == "2.3.5"
      @tt.transform("2.3.4").should == "4"  # two subtrees!
    end
    it "handles removing nodes" do
      @tt.remove("3")
      @tt.remove("5")
      @tt.transform("1.2.3").should == "2"
      @tt.transform("1.2.4").should == "2.4"
      @tt.transform("1.9.8.2.4.5.3.6").should == "2.4.6"
    end
    it "handles removing ranks" do
      @tt.remove_rank("no rank")
      @tt.transform("1.2.3.4").should == "3.4"
      @tt.transform("1.2").should == nil
    end
    it "handles removing ranks in the middle" do
      @tt.remove_rank("subgenus")
      @tt.transform("1.2.3.4").should == "2.4"
    end
    it "prunes branches" do
      @tt.prune("3")
      @tt.transform("1.2.4").should == "2.4"
      @tt.transform("1.2.3.4").should == nil
    end
    it "looks up the ranks correctly" do
      r = @tt.send(:get_ranks, ["1", "2", "3", "4", "5"])
      r.should == ["genus", "no rank", "subgenus", "species", "species"]
    end
  end
end
