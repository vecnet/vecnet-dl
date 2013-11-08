require 'spec_helper'
require 'stringio'
require 'ncbi_tools'

describe "ncbi_tools" do
  before do
    @ncbi = NcbiTools.new
  end
  describe "create_synonym_file" do
  end

  describe "tree_number" do
    it "recurses correctly" do
      taxons = {"1" => {parentid: "1"}, "2" => {parentid: "3"}, "3" => {parentid: "1"}}
      @ncbi.send(:tree_number, taxons, "2").should == "1.3.2"
      @ncbi.send(:tree_number, taxons, "1").should == "1"
      @ncbi.send(:tree_number, taxons, "3").should == "1.3"
    end
  end

  describe "parse_names_file" do
    before(:all) do
      @sample_input = <<EOS
5737\t|\tMonocercomonas sp.\t|\t\t|\tscientific name\t|
5738\t|\tDiplomonadida\t|\t\t|\tscientific name\t|
5738\t|\tdiplomonads\t|\t\t|\tcommon name\t|
5738\t|\tdiplomonads\t|\tdiplomonads<blast5738>\t|\tblast name\t|
5739\t|\tHexamitidae\t|\t\t|\tscientific name\t|
5740\t|\tGiardia\t|\t\t|\tscientific name\t|
5740\t|\tGiardia Kunstler\t|\t\t|\tauthority\t|
5741\t|\tGiardia duodenalis\t|\t\t|\tsynonym\t|
5741\t|\tGiardia intestinalis\t|\t\t|\tscientific name\t|
5741\t|\tGiardia intestinalis (Lambl, 1859) Kofoid & Christiansen, 1915\t|\t\t|\tauthority\t|
5741\t|\tGiardia lamblia\t|\t\t|\tgenbank synonym\t|
5741\t|\tLamblia intestinalis\t|\t\t|\tsynonym\t|
5742\t|\tGiardia muris\t|\t\t|\tscientific name\t|
5743\t|\tGiardia ardeae\t|\t\t|\tscientific name\t|
5744\t|\tGiardia sp.\t|\t\t|\tscientific name\t|
5747\t|\tEustigmatophyceae\t|\t\t|\tscientific name\t|
5747\t|\tEustigmatophyta\t|\t\t|\tsynonym\t|
5747\t|\talgae\t|\talgae <Eustigmatophyceae>\t|\tin-part\t|
5747\t|\teustigmatophytes\t|\t\t|\tcommon name\t|
EOS
    end
    it "performs correctly" do
      f = StringIO.new(@sample_input)
      File.stub(:open).with("dummy").and_yield(f)
      r = @ncbi.send(:parse_names_file, "dummy")
      r.should == {
        "5737" => ["Monocercomonas sp."],
        "5738" => ["Diplomonadida", "diplomonads", "diplomonads"],
        "5739" => ["Hexamitidae"],
        "5740" => ["Giardia"],
        "5741" => ["Giardia intestinalis", "Giardia duodenalis", "Giardia lamblia", "Lamblia intestinalis"],
        "5742" => ["Giardia muris"],
        "5743" => ["Giardia ardeae"],
        "5744" => ["Giardia sp."],
        "5747" => ["Eustigmatophyceae", "Eustigmatophyta", "eustigmatophytes"]
      }
    end
  end
end
