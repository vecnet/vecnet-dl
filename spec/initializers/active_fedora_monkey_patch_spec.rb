require 'spec_helper'

describe 'active fedora monkey patches' do
  let(:user) { FactoryGirl.create(:user) }
  let(:generic_file) { FactoryGirl.create_generic_file(:collection,user) }
  it 'cannot delete' do
    generic_file_pid = generic_file.pid

    content_datastream_url = generic_file.datastreams['content'].url
    datastream_url = content_datastream_url.split("/")[0..-2].join("/")

    # Why is this not ActiveFedora::ActiveObjectNotFoundError?
    # Because I am access the Fedora API, not using the ActiveFedora behavior
    expect {
      generic_file.inner_object.repository.client["#{datastream_url}?format=xml"].get
    }.to raise_error(RestClient::Unauthorized)

    expect {
      GenericFile.find(generic_file_pid)
    }.to raise_error(ActiveFedora::ActiveObjectNotFoundError)

    expect(ActiveFedora::Base.exists?(generic_file_pid)).to eq(true)
  end

end
