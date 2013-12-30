require 'spec_helper'

describe CurationConcern::CollectionsController do
  render_views
  let(:user) { FactoryGirl.create(:user) }
  let(:collection) { FactoryGirl.create_curation_concern(:collection, user) }

  before do
    controller.stub(:curation_concern).and_return(collection)
  end

  describe '#new' do
    it 'requires authentication' do
      get :new
      response.status.should == 401
    end
    it 'renders when signed in' do
      warden.set_user(user)
      get :new
      response.status.should == 302
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

    it 'raise user not signed in error if user is not logged in' do
      post :create, collection: { title: "Title"}
      response.status.should == 401
    end

    it 'requires authentication' do
      warden.set_user(user)
      get :new
      expect(response).to redirect_to(new_curation_concern_generic_file_path(collection))
    end

    it 'redirects to parent when successful' do
      warden.set_user(user)
      controller.actor = successful_actor

      post(
          :create,
          collection: { title: "Title"}
      )

      expect(response).to(
          redirect_to(new_curation_concern_generic_file_path(collection))
      )
    end

    it 'renders form when unsuccessful' do
      warden.set_user(user)
      controller.actor = failing_actor
      post(
          :create,
          collection: { title: "Title"}
      )
      response.status.should == 422
    end

  end

end
