require 'spec_helper'

describe CurationConcern::GenericFilesController do
  render_views
  let(:user) { FactoryGirl.create(:user) }
  let(:another_user) { FactoryGirl.create(:user) }
  let(:parent) { FactoryGirl.create_curation_concern(:collection, user) }
  let(:file) { Rack::Test::UploadedFile.new(__FILE__, 'text/plain', false) }
  let(:generic_file) { FactoryGirl.create_generic_file(parent, user) }
  let(:another_user) { FactoryGirl.create(:user) }

  describe '#new' do
    it 'renders a form if you are logged in' do
      parent
      warden.set_user(user)
      get(:new, parent_id: parent.to_param)
      response.should be_successful
      expect(response).to render_template('new')
    end

    it 'redirects if you are not logged in' do
      warden.set_user(nil)
      parent
      #expect {
        get :new, parent_id: parent.to_param
      #}.to raise_rescue_response_type(:unauthorized)
      response.status.should == 401
      puts "Response: #{response.body}"
    end
  end

  describe '#create' do
    let(:actor) { double('actor') }
    let(:actors_action) { :create! }
    let(:invalid_exception) {
      ActiveFedora::RecordInvalid.new(ActiveFedora::Base.new)
    }
    let(:failing_actor) {
      actor.should_receive(actors_action).and_raise(invalid_exception)
      actor
    }
    let(:successful_actor) {
      actor.should_receive(actors_action).and_return(true)
      actor
    }

    it 'redirects to parent when successful' do
      warden.set_user(user)
      parent
      controller.actor = successful_actor

      post(
        :create,
        parent_id: parent.to_param,
        generic_file: { title: "Title", file: file }
      )

      expect(response).to(
        redirect_to(dashboard_index_path)
      )
    end

    it 'renders form when unsuccessful' do
      warden.set_user(user)
      parent
      controller.actor = failing_actor

      post(
        :create,
        parent_id: parent.to_param,
        generic_file: { title: "Title", file: file }
      )

      expect(response).to render_template('new')
      response.status.should == 422
    end

  end

  describe '#edit' do
    it 'should be successful' do
      generic_file
      warden.set_user(user)
      get :edit, id: generic_file.to_param
      controller.curation_concern.should be_kind_of(GenericFile)
      response.should be_successful
    end
  end

  describe '#update' do
    let(:updated_title) { Time.now.to_s }
    let(:failing_actor) {
      actor.
      should_receive(:update!).
      and_raise(ActiveFedora::RecordInvalid.new(ActiveFedora::Base.new))
      actor
    }
    let(:successful_actor) {
      actor.should_receive(:update!).and_return(true)
      actor
    }
    let(:actor) { double('actor') }
    it 'renders form when unsuccessful' do
      generic_file
      controller.actor = failing_actor
      warden.set_user(user)
      put :update, id: generic_file.to_param, generic_file: {title: updated_title}
      expect(response).to render_template('edit')
      response.status.should == 422
    end

    it 'redirects to edit page when successful' do
      generic_file
      warden.set_user(user)
      put :update, id: generic_file.to_param, generic_file: {title: updated_title}
      response.status.should == 302
      expect(response).to(
        redirect_to(
          controller.edit_polymorphic_path([:curation_concern, generic_file])
        )
      )
    end
  end

  describe '#show' do
    it 'should be successful if logged in' do
      generic_file
      warden.set_user(user)
      get :show, id: generic_file.to_param
      controller.curation_concern.should be_kind_of(GenericFile)
      response.should be_successful
    end

    it 'does not allow another user to view it' do
      generic_file
      warden.set_user another_user
      expect {
        get :show, id: generic_file.to_param
      }.to raise_rescue_response_type(:unauthorized)
    end
  end

  describe '#destroy' do
    it 'should be successful if file exists' do
      parent = generic_file.batch
      warden.set_user(user)
      delete :destroy, id: generic_file.to_param
      expect(response.status).to eq(302)
      expect(response).to redirect_to(dashboard_index_path)
    end
  end
end
