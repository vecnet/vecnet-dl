require 'spec_helper'

describe MeshDataParser do

  it "parses a record correctly" do
    data = <<-EOS
*NEWRECORD
A = 45
B = a = b = c = d
B = more than one
EOS
    mesh = MeshDataParser.new(StringIO.new(data))
    records = mesh.all_records
    records.length.should == 1
    records[0].should == {'A'=>['45'],'B'=>['a = b = c = d','more than one']}
  end

  it "handles more two records" do
    data = <<-EOS
*NEWRECORD
A = 45
B = a = b = c = d

*NEWRECORD
A = another field
print entry = test

EOS
    mesh = MeshDataParser.new(StringIO.new(data))
    records = mesh.all_records
    records.length.should == 2
    records[0].should == {'A'=>['45'],'B'=>['a = b = c = d']}
    records[1].should == {'A'=>['another field'], 'print entry'=>['test']}
  end

  it 'ignores bad input' do
    data = <<-EOS
*NEWRECORD
A = 45
B=no space
 space at beginning of line and no =
*NEWRECORD
EOS
    mesh = MeshDataParser.new(StringIO.new(data))
    records = mesh.all_records
    records.length.should == 2
    records[0].should == {'A'=>['45']}
    records[1].should == {}
  end

  it 'parses a sample mesh file' do
    mesh = MeshDataParser.new(File.new(Rails.root + 'spec/sample-mesh.txt'))
    records = mesh.all_records
    records.length.should == 2
    records[0].should == {
      "RECTYPE" => ["D"],
      "MH" => ["Calcimycin"],
      "AQ" => ["AA AD AE AG AI AN BI BL CF CH CL CS CT DU EC HI IM IP ME PD PK PO RE SD ST TO TU UR"],
      "ENTRY" => ["A-23187|T109|T195|LAB|NRW|NLM (1991)|900308|abbcdef",
        "A23187|T109|T195|LAB|NRW|UNK (19XX)|741111|abbcdef",
        "Antibiotic A23187|T109|T195|NON|NRW|NLM (1991)|900308|abbcdef",
        "A 23187",
        "A23187, Antibiotic"],
      "MN" => ["D03.438.221.173"],
      "PA" => ["Anti-Bacterial Agents", "Calcium Ionophores"],
      "MH_TH" => ["NLM (1975)"],
      "ST" => ["T109", "T195"],
      "N1" => ["4-Benzoxazolecarboxylic acid, 5-(methylamino)-2-((3,9,11-trimethyl-8-(1-methyl-2-oxo-2-(1H-pyrrol-2-yl)ethyl)-1,7-dioxaspiro(5.5)undec-2-yl)methyl)-, (6S-(6alpha(2S*,3S*),8beta(R*),9beta,11alpha))-"],
      "RN" => ["52665-69-7"],
      "PI" => ["Antibiotics (1973-1974)", "Carboxylic Acids (1973-1974)"],
      "MS" => ["An ionophorous, polyether antibiotic from Streptomyces chartreusensis. It binds and transports CALCIUM and other divalent cations across membranes and uncouples oxidative phosphorylation while inhibiting ATPase of rat liver mitochondria. The substance is used mostly as a biochemical tool to study the role of divalent cations in various biological systems."],
      "OL" => ["use CALCIMYCIN to search A 23187 1975-90"],
      "PM" => ["91; was A 23187 1975-90 (see under ANTIBIOTICS 1975-83)"],
      "HN" => ["91(75); was A 23187 1975-90 (see under ANTIBIOTICS 1975-83)"],
      "MED" => ["*62", "847"],
      "M90" => ["*299", "2405"],
      "M85" => ["*454", "2878"],
      "M80" => ["*316", "1601"],
      "M75" => ["*300", "823"],
      "M66" => ["*1", "3"],
      "M94" => ["*153", "1606"],
      "MR" => ["20110624"],
      "DA" => ["19741119"],
      "DC" => ["1"],
      "DX" => ["19840101"],
      "UI" => ["D000001"]
    }
    records[1].should == {
      "RECTYPE" => ["D"],
      "MH" => ["Temefos"],
      "AQ" => ["AA AD AE AG AI AN BL CF CH CL CS CT DU EC HI IM IP ME PD PK RE SD ST TO TU UR"],
      "ENTRY" => ["Abate|T115|T131|TRD|NRW|NLM (1996)|941114|abbcdef",
        "Difos|T115|T131|TRD|NRW|UNK (19XX)|861007|abbcdef",
        "Temephos|T115|T131|TRD|EQV|NLM (1996)|941201|abbcdef"],
      "MN" => ["D02.705.400.625.800",
        "D02.705.539.345.800",
        "D02.886.300.692.800"],
      "PA" => ["Insecticides"],
      "MH_TH" => ["INN (19XX)", "USAN (1974)"],
      "ST" => ["T115", "T131"],
      "N1" => ["Phosphorothioic acid, O,O'-(thiodi-4,1-phenylene) O,O,O',O'-tetramethyl ester"],
      "RN" => ["3383-96-8"],
      "AN" => ["for use to kill or control insects, use no qualifiers on the insecticide or the insect; appropriate qualifiers may be used when other aspects of the insecticide are discussed such as the effect on a physiologic process or behavioral aspect of the insect; for poisoning, coordinate with ORGANOPHOSPHATE POISONING"],
      "PI" => ["Insecticides (1966-1971)"],
      "MS" => ["An organothiophosphate insecticide."],
      "PM" => ["96; was ABATE 1972-95 (see under INSECTICIDES, ORGANOTHIOPHOSPHATE 1972-90)"],
      "HN" => ["96; was ABATE 1972-95 (see under INSECTICIDES, ORGANOTHIOPHOSPHATE 1972-90)"],
      "MED" => ["*4", "8"],
      "M90" => ["*19", "29"],
      "M85" => ["*16", "22"],
      "M80" => ["*22", "31"],
      "M75" => ["*15", "19"],
      "M66" => ["*6", "16"],
      "M94" => ["*15", "24"],
      "MR" => ["20120703"],
      "DA" => ["19990101"],
      "DC" => ["1"],
      "DX" => ["19910101"],
      "UI" => ["D000002"]
    }
  end
end

