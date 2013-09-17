require 'spec_helper'
#require File.expand_path("../../../app/models/geoname_location", __FILE__)

class LocationTest < ActiveFedora::Base
  include GeonameLocation
  attr_accessor :based_near
end

describe GeonameLocation do

  let(:model) {
    Class.new(ActiveFedora::Base) {
      include GeonameLocation
      attr_accessor :based_near
    }
  }
  subject { model.new }

  it { should respond_to(:format_based_near_from_location) }
  it { should respond_to(:geoname_locations) }
  context 'should returns encoded value' do
    subject { LocationTest.new }
    let(:location_with_id) { ["locatio|0", "Lond Pharrak, Balochistn, Pakistan|1345791"]   }
    it "having both location and id" do
      subject.geoname_locations = location_with_id
      subject.format_based_near_from_location.should==["name=locatio;geoname_id=0", "name=Lond Pharrak, Balochistn, Pakistan;geoname_id=1345791"]
    end
  end

  context "test only longitude" do
    let(:location_array) {["location", "locationtest", "test"]}
    let(:location_with_id) {["location|10", "Lond Pharrak, Balochistn, Pakistan|1345791", "test"]}
    it "encode with id" do
      subject.based_near = location_array
      subject.geoname_locations = location_with_id
      subject.format_based_near_from_location.should== ["name=location;geoname_id=10", "name=test"]
    end
  end

  describe "decode giving string to location objects" do

    context "decode location in repository" do
      let(:based_near) { "name=location;geoname_id=10" }
      it "decode to hash"do
      GeonameLocation::Location.decode_location(based_near).should be_kind_of(Hash)
      end
      it "parse given string to location object"do
        GeonameLocation::Location.parse_location(based_near).should be_instance_of(GeonameLocation::Location)
      end
      it "return formatted string in right format"do
        GeonameLocation::Location.parse_location(based_near).formatted_location.should == "location|10"
      end
    end

    context "decode location in repository" do
      let(:based_near) { "name=location;" }
      let(:based_near_id_only) {"geoname_id=100"}

      it "format given string to location with id as 0"do
        GeonameLocation::Location.parse_location(based_near).formatted_location.should == "location|0"
      end

      it "should raise error when no name is available"do
        expect{
          GeonameLocation::Location.parse_location(based_near_id_only).formatted_location
        }.to raise_error(RuntimeError)
      end
    end

  end
end