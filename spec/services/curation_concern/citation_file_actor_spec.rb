require 'spec_helper'

describe CurationConcern::CitationFileActor do
  let(:user) { FactoryGirl.create(:user) }
  let(:parent) {
    FactoryGirl.create_curation_concern(:citation, user)
  }
  let(:file_path) { __FILE__ }
  let(:file) { Rack::Test::UploadedFile.new(file_path, 'text/plain', false)}
  let(:file_content) { File.read(file)}
  let(:title) { Time.now.to_s }
  let(:attributes) {
    { file: file, title: title, visibility: 'psu' }
  }

  subject {
    CurationConcern::CitationFileActor.new(citation_file, user, attributes)
  }

  describe '#create!' do
    let(:citation_file) { CitationFile.new.tap {|gf| gf.batch = parent } }
    let(:reloaded_citation_file) {
      citation_file.class.find(citation_file.pid)
    }
    describe 'with a file' do
      it 'succeeds if attributes are given' do
        expect {
          subject.create!
        }.to change {
          parent.class.find(parent.pid).generic_files.count
        }.by(1)

        reloaded_citation_file.batch.should == parent
        reloaded_citation_file.to_s.should == title
        reloaded_citation_file.filename.should == File.basename(__FILE__)

        expect(reloaded_citation_file.to_solr['read_access_group_t']).to eq(['registered'])
      end

      it 'fails if no batch is provided' do
        citation_file.batch = nil
        expect {
          expect {
            subject.create!
          }.to raise_error(ActiveFedora::RecordInvalid)
        }.to_not change { CitationFile.count }
      end
    end

    describe 'without a file' do
      let(:file) { nil }
      it 'fails if no batch is provided' do
        expect{
          expect {
            subject.create!
          }.to raise_error(ActiveFedora::RecordInvalid)
        }.to_not change { CitationFile.count }
      end
    end
  end

  describe '#update!' do
    let(:citation_file) {
      FactoryGirl.create_citation_file(parent, user)
    }
    it do
      citation_file.title.should_not == title
      citation_file.content.content.should_not == file_content
      expect {
        subject.update!
      }.to change {citation_file.versions.count}.by(1)
      citation_file.title.should == title
      citation_file.to_s.should == title
      citation_file.content.content.should == file_content
    end
  end
end
