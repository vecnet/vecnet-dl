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
  let(:create_date) { DateTime.new(2000,-11,-26,-20,-55,-54,'+7') }
  let(:date_uploaded) { DateTime.new(2001,-11,-26,-20,-55,-54,'+7') }
  let(:modified_date) { DateTime.new(2002,-11,-26,-20,-55,-54,'+7') }
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

  it 'to_s' do
    puts "title:#{fedora_object.title}"
    subject.to_endnote.should == ''
  end

end