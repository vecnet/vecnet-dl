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
  let(:user) { FactoryGirl.create(:user) }

  let(:vecnet_generic_file) {
    FactoryGirl.create_generic_file(:collection, user)
  }

  describe 'validating metadata' do
    it 'uses #noid for #to_param' do
      subject.to_param.should == subject.noid
    end

    it 'has no title to display' do
      subject.to_s.should == "No Title"
    end

    let(:persisted_generic_file) {
      FactoryGirl.create_generic_file(:collection, user)
    }

    it 'has a current version id' do
      persisted_generic_file.current_version_id.should == "content.0"
    end

    it 'has file_name as its title to display' do
      persisted_generic_file.to_s.should_not == "No Title"
    end
  end

  describe 'saving spatial coverage' do
    let(:latitude) {'lat'}
    let(:longitude) {'long'}
    let(:vecnet_generic_file) {
      FactoryGirl.create_generic_file(:collection, user)
    }
    let(:latitude_array) {["lat1","lat2"]}
    let(:longitude_array) { ["long1","long2"]}

    context 'set spatial from latitude and longitude' do
      it 'should encode latitude and longitude' do
        vecnet_generic_file.latitude = [latitude]
        vecnet_generic_file.longitude = [longitude]
        vecnet_generic_file.format_spatials_from_lat_long.should==["north=lat;east=long"]
      end
      it 'should be not set spatials if only latitude available' do
        vecnet_generic_file.latitude = [latitude]
        vecnet_generic_file.format_spatials_from_lat_long.should==[]
      end
      it 'should be not set spatials if only longitude available' do
        vecnet_generic_file.longitude = [longitude]
        vecnet_generic_file.format_spatials_from_lat_long.should==[]
      end
      it 'should be error on spatials' do
        vecnet_generic_file=GenericFile.new
        vecnet_generic_file.longitude = [longitude]
        vecnet_generic_file.valid?
        vecnet_generic_file.errors[:spatials].should == ['Invalid Spatial Data. latitude is blank']
      end
      it 'should save encoded latitude and longitude to spatials' do
        vecnet_generic_file.latitude = [latitude]
        vecnet_generic_file.longitude = [longitude]
        vecnet_generic_file.save
        GenericFile.find(vecnet_generic_file.pid).spatials.should_not be_empty
        GenericFile.find(vecnet_generic_file.pid).spatials.first.should be_instance_of(Spatial)
      end
    end

    context 'set spatials from latitude and longitude array' do
      before {
        vecnet_generic_file.latitude=latitude_array
        vecnet_generic_file.longitude=longitude_array
      }
      it 'should encode the array to spatials' do
        vecnet_generic_file.format_spatials_from_lat_long.should==["north=lat1;east=long1", "north=lat2;east=long2"]
      end
      it 'should decode to latitude and longitude from spatial array' do
        vecnet_generic_file.format_spatials_from_lat_long
        vecnet_generic_file.save
        gf=GenericFile.find(vecnet_generic_file.pid)
        gf.spatials.size.should == 2
      end
    end
  end

  describe 'saving temporal coverage' do
    let(:start_time) {'start'}
    let(:end_time) {'end'}
    let(:empty) {""}
    let(:start_time_array) {["start1","start2"]}
    let(:end_time_array) { ["end1","end2"]}

    context 'set temporal from start and end time' do
      it 'should encode start_time and end_time' do
        vecnet_generic_file.start_time = [start_time]
        vecnet_generic_file.end_time = [end_time]
        vecnet_generic_file.format_temporals_from_start_end_time.first.should=="start=start;end=end"
      end
      it 'should set the end time' do
        vecnet_generic_file.start_time = [empty]
        vecnet_generic_file.end_time = [end_time]
        vecnet_generic_file.format_temporals_from_start_end_time.should==["end=end"]
      end
      it 'should set the start time' do
        vecnet_generic_file.start_time = [start_time]
        vecnet_generic_file.end_time = [empty]
        vecnet_generic_file.format_temporals_from_start_end_time.should==["start=start"]
      end
      it 'should save encoded start_time and end_time to temporals' do
        vecnet_generic_file.start_time = [start_time]
        vecnet_generic_file.end_time = [end_time]
        vecnet_generic_file.save
        GenericFile.find(vecnet_generic_file.pid).temporals.should_not be_empty
        GenericFile.find(vecnet_generic_file.pid).temporals.first.should be_instance_of(Temporal)
      end
    end

    context 'set temporals from start_time and end_time array' do
      before {
        vecnet_generic_file.start_time=start_time_array
        vecnet_generic_file.end_time=end_time_array
      }
      it 'should encode the array to temporals' do
        vecnet_generic_file.format_temporals_from_start_end_time.should==["start=start1;end=end1", "start=start2;end=end2"]
      end
      it 'should decode to start_time and end_time from spatial array' do
        vecnet_generic_file.format_temporals_from_start_end_time
        vecnet_generic_file.save
        gf=GenericFile.find(vecnet_generic_file.pid)
        gf.temporals.size.should == 2
      end
    end
  end
end
