require 'spec_helper'
describe Spatial do
  subject {Spatial.new(lat, long)}
  context "" do
    context "test lat and long" do
      let(:lat) { "1" }
      let(:long) { "2" }
      it do
        subject.latitude.should == lat
        subject.longitude.should == long
        subject.encode_dcsv.should== "north=#{long}; east=#{lat} "
      end
    end

    context "test only longitude" do
      let(:lat) {""}
      let(:long) {"value"}
      it do
       subject.encode_dcsv.should== "east=#{long}"
      end
    end

    context "test only latitude" do
      let(:lat) {"value"}
      let(:long) {""}
      it do
        subject.encode_dcsv.should== "north=#{lat}"
      end
    end
  end
end



