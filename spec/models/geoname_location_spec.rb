require 'spec_helper'
#require File.expand_path("../../../app/models/geoname_location", __FILE__)

class LocationTest
  include GeonameLocation
  attr_accessor :based_near
end

describe GeonameLocation do

  subject { LocationTest.new }

  #before { subject.geoname_locations = location_array }
  it { should respond_to(:format_based_near_from_location) }
  let(:location_array) { ["locatio|0", "India, , India|1269750", "Lond Pharrak, Balochistn, Pakistan|1345791", "Lond Pharrak, Balochistan|0", "", "hello|0"]   }
  context 'should retuns encoded value' do

    subject.geoname_locations = location_array
    subject.format_based_near_from_location.should==[]
  end
end