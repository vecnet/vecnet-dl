require 'spec_helper'

describe CharacterizeJob do

  # I'm not entirely certain where I want to put this. Given that it is
  # leaning on an actor, I'd like to put it there. But actors are going to
  # push to a queue, so it is the worker that should choke.
  describe '#run' do
    let(:user) { FactoryGirl.create(:user) }
    let(:collection) {
      FactoryGirl.create_curation_concern(:collection, user)
    }
    it 'will not deletes the generic file when I upload a virus since vecnet not use CLAMAV' do
      EnvironmentOverride.with_anti_virus_scanner(false) do
        expect {
          FactoryGirl.create_generic_file(collection, user)
        }.to raise_error(AntiVirusScanner::VirusDetected)
        expect(collection.generic_files.count).to eq(1)
      end
    end
  end
end
