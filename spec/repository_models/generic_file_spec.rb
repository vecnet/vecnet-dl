require 'spec_helper'
describe GenericFile do
  subject { GenericFile.new }

  it { should respond_to(:versions) }
  it { should respond_to(:human_readable_type) }
  it { should respond_to(:current_version_id) }
  it { should respond_to(:file=) }
  it { should respond_to(:filename) }
  it { should respond_to(:visibility) }
  it { should respond_to(:visibility=) }

  it 'uses #noid for #to_param' do
    subject.to_param.should == subject.noid
  end

  it 'has no title to display' do
    subject.to_s.should == "No Title"
  end

  let(:user) { FactoryGirl.create(:user) }
  let(:persisted_generic_file) {
    FactoryGirl.create_generic_file(:senior_thesis, user)
  }

  it 'has a current version id' do
    persisted_generic_file.current_version_id.should == "content.0"
  end

  it 'has file_name as its title to display' do
    persisted_generic_file.to_s.should_not == "No Title"
  end

  describe 'saving spatial coverage' do
    let(:latitude) {'lat'}
    let(:longitude) {'long'}
    let(:generic_file) {
      FactoryGirl.create_generic_file(:collection, user)
    }

    let(:latitude_array) {["lat1","lat2"]}
    let(:longitude_array) { ["long1","long2"]}

    context 'set spatial from latitude and longitude' do
      it 'should encode latitude and longitude' do
        generic_file.latitude = [latitude]
        generic_file.longitude = [longitude]
        generic_file.format_spatials_from_lat_long=="north=lat;east=long"
      end
      it 'should be not set spatials if only latitude available' do
        generic_file.latitude = [latitude]
        generic_file.format_spatials_from_lat_long==[]
      end
      it 'should be not set spatials if only longitude available' do
        generic_file.longitude = [longitude]
        generic_file.format_spatials_from_lat_long==[]
      end
      it 'should be error on spatials' do
        generic_file=GenericFile.new
        generic_file.longitude = [longitude]
        generic_file.valid?
        generic_file.errors[:spatials].should == ['Invalid Spatial data, Latitude and Longitude must be of same length']
      end
      it 'should save encoded latitude and longitude to spatials' do
        generic_file.latitude = [latitude]
        generic_file.longitude = [longitude]
        generic_file.save
        GenericFile.find(generic_file.pid).spatials.should_not be_empty
        GenericFile.find(generic_file.pid).spatials.first.should be_instance_of(Spatial)
      end
    end

    context 'set spatials from latitude and longitude array' do
      before {
        generic_file.latitude=latitude_array
        generic_file.longitude=longitude_array
      }
      it 'should encode the array to spatials' do
        generic_file.format_spatials_from_lat_long==["north=lat1;east=long1", "north=lat2;east=long2"]
      end
      it 'should decode to latitude and longitude from spatial array' do
        generic_file.format_spatials_from_lat_long
        generic_file.save
        gf=GenericFile.find(generic_file.pid)
        gf.spatials.size.should == 2
      end
    end
  end
end
