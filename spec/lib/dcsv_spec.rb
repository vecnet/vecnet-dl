require 'spec_helper'
require 'dcsv'

describe Dcsv do
  describe "decode" do
    it "handles escaped characters" do
      output = Dcsv.decode("a;b\\;c=hello;d\\=nothing=nothing;e;")
      output.should == {  0 => "a",
                          "b;c" => "hello",
                          "d=nothing" => "nothing",
                          1 => "e"
                       }
    end
    it "handles values with escaped =" do
      output = Dcsv.decode("a;b\\=c;d;")
      output.should == {  0 => "a",
                          1 => "b=c",
                          2 => "d"
                       }
    end
  end

  describe "encode" do
    it "escapes strings correctly" do
      output = Dcsv.encode("=ab;")
      output.should == "\\=ab\\;"
    end
    it "converts hashes recursively" do
      output = Dcsv.encode({"a" => "b", "c=d" => ";"})
      output.should == "a=b;c\\=d=\\;"
    end
    it "notices array indexing and encodes that" do
      output = Dcsv.encode({0 => "a=b", 1 => ";", 2 => "asdf", "123" => "+345"})
      output.should == "a\\=b;\\;;asdf;123=+345"
    end
  end
end
