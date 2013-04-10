require 'spec_helper'
describe Spatial do
  subject {Spatial.new(latitude, longitude)}
  describe "Encode latitude and longitude to spatial objects" do
    context "test latitude and longitude" do
      let(:latitude) { "1" }
      let(:longitude) { "2" }
      it do
        subject.latitude.should == latitude
        subject.longitude.should == longitude
        subject.encode_dcsv.should== "north=#{latitude};east=#{longitude}"
      end
    end

    context "test only longitude" do
      let(:latitude) {""}
      let(:longitude) {"value"}
      it do
       subject.encode_dcsv.should== "east=#{longitude}"
      end
    end

    context "test only latitude" do
      let(:latitude) {"value"}
      let(:longitude) {""}
      it do
        subject.encode_dcsv.should== "north=#{latitude}"
      end
    end
  end

  describe "decode giving string to spatial objects" do
    let(:dscv_spatial) { "north=testing2;east=tesing1" }
    it "decode to hash"do
      Spatial.decode(dscv_spatial).should be_kind_of(Hash)
    end
    it "parse given string to spatial object"do
      Spatial.parse_spatial(dscv_spatial).should be_instance_of(Spatial)
    end
  end

end



