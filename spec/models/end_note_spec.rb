require 'active_model'
require 'rspec/rails/extensions'
require 'ostruct'
require File.expand_path('app/models/end_note')


describe EndNote do

  subject { EndNote.new(fedora_object) }

  let(:pid) { "TEST:#{noid}" }
  let(:noid) { '1234' }
  let(:title) { 'My Title' }
  let(:creator) { 'My creator' }
  let(:publication_place) { 'My publication_place' }
  let(:contributor) { 'My contributor' }
  let(:publisher) { 'My publisher' }
  let(:series_title) { 'My series_title' }
  let(:isbn) { 'My isbn' }
  let(:related_url) { 'My related_url' }
  let(:edition_statement) { 'My edition_statement' }
  let(:persistent_url) { 'My persistent_url' }
  let(:description) { 'My description' }
  let(:language) { 'My language' }
  let(:resource_type) { 'My resource_type' }
  let(:create_date) { DateTime.new(2000,-11,-26,-20,-55,-54,'7') }
  let(:date_uploaded) { DateTime.new(2001,-11,-26,-20,-55,-54,'7') }
  let(:modified_date) { DateTime.new(2002,-11,-26,-20,-55,-54,'7') }
  let(:fedora_object) {
    OpenStruct.new(
       {
        to_param: noid,
        title: title,
        creator: creator,
        publication_place: publication_place,
        date_created: create_date.to_s,
        date_uploaded: date_uploaded.to_s,
        contributor: contributor,
        publisher: publisher,
        series_title: series_title,
        isbn: isbn,
        related_url: related_url,
        edition_statement: edition_statement,
        persistent_url: persistent_url,
        description: description,
        language: language,
        date_modified: modified_date.to_s,
        resource_type: resource_type
      }
    )
  }


  it 'to_endnote prints endnote format of attributes' do
    subject.to_endnote.should == "%0 OpenStruct\n%T My Title\n%Q \n%A My creator\n%C My publication_place\n%D 2000-02-04T04:05:06+00:00\n%8 2001-02-03T04:05:06+00:00\n%E My contributor\n%I My publisher\n%J My series_title\n%@ My isbn\n%U My related_url\n%7 My edition_statement\n%R My persistent_url\n%X My description\n%G My language\n%[ 2002-02-03T04:05:06+00:00\n%9 My resource_type\n%~ VecNet Digital Library\n%W TBD"
  end
  context "with no attributes" do
    let(:fedora_object){{}}
    it 'to_endnote is empty when there is no attributes' do
      subject.to_endnote.should == "%0 Hash\n%Q \n%~ VecNet Digital Library\n%W TBD"
    end
  end

end