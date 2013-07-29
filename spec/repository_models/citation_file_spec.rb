require 'spec_helper'
describe CitationFile do
  subject { CitationFile.new }

  it { should respond_to(:versions) }
  it { should respond_to(:human_readable_type) }
  it { should respond_to(:current_version_id) }
  it { should respond_to(:file=) }
  it { should respond_to(:filename) }
  it { should respond_to(:visibility) }
  it { should respond_to(:visibility=) }
  it { should respond_to(:extract_content) }
  let(:user) { FactoryGirl.create(:user) }

  let(:citation_file) {
    FactoryGirl.create_citation_file(:citation, user, {:visibility=>'public'})
  }

  describe 'validating metadata' do
    it 'uses #noid for #to_param' do
      subject.to_param.should == subject.noid
    end

    it 'has no title to display' do
      subject.to_s.should == "No Title"
    end

    let(:persisted_citation_file) {
      FactoryGirl.create_citation_file(:citation, user, {:visibility=>'public'})
    }

    it 'has a current version id' do
      persisted_citation_file.current_version_id.should == "content.0"
    end

    it 'has file_name as its title to display' do
      persisted_citation_file.to_s.should_not == "No Title"
    end
  end
end
