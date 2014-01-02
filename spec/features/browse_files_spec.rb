require 'spec_helper'

describe "Browse files" do

  before(:all) do
    @user=FactoryGirl.create(:user)
    find_or_create_file_fixtures_with_user(@user)
  end

  after(:all) do
    puts "clean all objects"
    t=ActiveFedora::Base.find(:all)
    t.each{|obj| obj.inner_object.delete}
    solr = ActiveFedora::SolrService.instance.conn
    solr.delete_by_query("*:*", params: {commit: true})
  end

  def has_facet?(text)
    within("#facets") do
      page.should have_selector('li > a', :text => text)
    end
  end

  describe "when not logged in" do
    it "should let us browse some of the public fixtures" do
      visit '/'
      page.assert_selector('h4', :text => 'Browse By', :visible => true)
      has_facet?('Resource Type')
      page.should have_css('.slide-list', visible: true)
      click_link "Article"
      page.should have_content "1 to 1 of 1"
      click_link "Fake Document Title"
      page.should have_content "Download"
      page.should_not have_content "Edit"
    end

    it "should not show private fixtures" do
      visit '/'
      page.assert_selector('h4', :text => 'Browse By', :visible => true)
      has_facet?('Resource Type')
      page.should have_css('.slide-list', visible: true)
      click_link "Article"
      page.should have_content "1 to 1 of 1"
      page.should have_css('h4 > a', count: 1)
      page.assert_selector('h4 > a', :text => "Fake Document Title")
    end
  end
  describe "when logged in" do
    before do
      login_as(@user)
    end
   it "should show private fixtures when logged as user" do
      visit '/'
      page.assert_selector('h4', :text => 'Browse By', :visible => true)
      has_facet?('Resource Type')
      page.should have_css('.slide-list', visible: true)
      click_link "Article"
      page.assert_selector('h4 > a', :text => "Fake Private Title")
      click_link "Fake Private Title"
      page.should have_content "Download"
      page.should have_content "Edit"
    end
  end
end
