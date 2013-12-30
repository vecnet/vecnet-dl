require 'spec_helper'

describe ClassifyConcernsController do
  render_views
  let(:user) { FactoryGirl.create(:user) }

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
    let(:user) { FactoryGirl.create(:user) }
    let(:collection) { FactoryGirl.create_curation_concern(:collection, user) }
    it 'raise user not signed in error if user is not logged in' do
      post :create, classify: { curation_concern_type: 'GenericFile' }
      response.status.should == 401
    end

    it 'requires authentication' do
      warden.set_user(user)
      get :new
      #response.should be_successful
      expect(response).to redirect_to(new_curation_concern_collection_path)
    end

  end
end
