require 'active_model'
require 'rspec/rails/extensions'
require File.expand_path('app/validators/spatial_validator')

class Validatable
  include ActiveModel::Validations
  attr_accessor :latitude, :longitude
  validates_with SpatialValidator
end

describe SpatialValidator do

  subject { Validatable.new }
  let(:latitude) {'lat'}
  let(:longitude) {'long'}

  let(:latitude_array) {["lat1","lat2"]}
  let(:longitude_array) { ["long1","long2"]}

  context 'validate latitude and longitude' do
    it 'should be valid when no latitude and longitude available' do
      subject.should be_valid
    end

    it 'should be valid when latitude and longitude are available' do
      subject.latitude = latitude
      subject.longitude = longitude
      subject.should be_valid
    end
    it 'should be not be valid' do
      subject.latitude = latitude
      subject.should_not be_valid
      should have(1).error_on(:longitude)
    end
    it 'should have error on latitude' do
      subject.longitude = longitude
      should have(1).error_on(:latitude)
    end
    it 'should have error on latitude' do
      subject.longitude = longitude
      subject.latitude = ""
      should have(1).error_on(:latitude)
    end
    it 'should have error on longitude' do
      subject.latitude = latitude
      should have(1).error_on(:longitude)
    end
    it 'should have error on longitude' do
      subject.latitude = latitude
      subject.longitude = ""
      should have(1).error_on(:longitude)
    end
  end

  context 'validate latitude and longitude array' do
    it 'should be valid when latitude and longitude are available' do
      subject.latitude = [latitude_array]
      subject.longitude = [longitude_array]
      subject.should be_valid
    end
    it 'should be valid when latitude and longitude are available' do
      subject.latitude = latitude_array
      subject.longitude = longitude
      subject.valid?
      should have(1).error
    end
  end

end