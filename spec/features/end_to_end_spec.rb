require 'spec_helper'

describe_options = {type: :feature}
if ENV['JS']
  describe_options[:js] = true
end

describe 'end to end behavior', describe_options do
  before(:each) do
    Warden.test_mode!
    @old_resque_inline_value = Resque.inline
    Resque.inline = true
  end
  after(:each) do
    Warden.test_reset!
    Resque.inline = @old_resque_inline_value
  end
  let(:user) { FactoryGirl.create(:user, agreed_to_terms_of_service: true) }
  let(:another_user) { FactoryGirl.create(:user, agreed_to_terms_of_service: true) }
  let(:prefix) { Time.now.strftime("%Y-%m-%d-%H-%M-%S-%L") }
  let(:initial_title) { "#{prefix} Something Special" }
  let(:initial_file_path) { __FILE__ }
  let(:updated_title) { "#{prefix} Another Not Quite" }
  let(:updated_file_path) { Rails.root.join('app/controllers/application_controller.rb').to_s }

  def assert_breadcrumb_trail(page, *breadcrumbs)
    page.assert_selector('.breadcrumb li', count: breadcrumbs.length)
    within('.breadcrumb') do
      breadcrumbs.each do |text, path|
        if String(path).empty?
          page.has_css?('li', text: text)
        else
          page.has_css?("li a[href='#{path}']", text: text)
        end
      end
    end
  end

  def click_upload_file
    within(".dropdown-menu") do
      click_on 'Upload a file'
    end
  end

  def create_mock_curation_concern(options = {})
    options['Title'] ||= initial_title
    options['Upload your thesis'] ||= initial_file_path
    options['Visibility'] ||= 'visibility_restricted'
    options["Button to click"] ||= "Save"
    options["Contributors"] ||= ["Dante"]
    options["Content License"] ||= Sufia::Engine.config.cc_licenses.keys.first

    page.should have_content('Create and Apply Metadata')
     within('#new_generic_file') do
      fill_in("Title", with: options['Title'])
      attach_file("generic_file_file", options['Upload your thesis'])
      choose(options['Visibility'])
      select(options['Content License'], from: I18n.translate('sufia.field_label.rights'))
      fill_out_form_multi_value_for('contributor', with: options['Contributors'])
      click_on(options["Button to click"])
    end
  end


  def fill_out_form_multi_value_for(method_name, options={})
    field_name = "generic_file[#{method_name}][]"
    within(".control-group.generic_file_#{method_name}.multi_value") do
      elements = [options[:with]].flatten.compact
      if with_javascript?
        elements.each_with_index do |element, i|
          container = all('.input-append').last
          within(container) do
            fill_in(field_name, with: element)
            click_on('Add')
          end
        end
      else
        fill_in(field_name, with: elements.first)
      end
    end
  end

  describe 'Able to login' do
    it "allows me to login" do
      login_as(user)
      visit new_classify_concern_path
      page.assert_selector('h1', :text => 'Create and Apply Metadata', :visible => true)
    end
  end

  describe 'breadcrumb' do
    it 'renders a breadcrumb' do
      login_as(user)
      visit new_classify_concern_path
      assert_breadcrumb_trail(page, ["Home", '/'], ["New Generic File", nil])
    end
  end

  describe 'with user who sign in' , js: true do
    before do
      login_as(user)
      visit '/'
      click_link 'Username 1'
    end

    it 'allows me to create a mock curation concern' do
      page.should have_css('.dropdown-menu', visible: true)
      click_upload_file
      page.assert_selector('h1', :text => 'Create and Apply Metadata', :visible => true)
    end

    it 'remembers mock curation concern inputs when data was invalid' do
      click_upload_file
      create_mock_curation_concern(
          'Visibility' => 'visibility_restricted',
          'I Agree' => true,
          'Title' => ''
      )
      page.assert_selector('.main-header h2', "Create and Apply Metadata")
      expect(page).to_not have_checked_field('visibility_restricted')
      expect(page).to have_checked_field('visibility_open')
    end
    #
    #it "a public item with future embargo is not visible today but is in the future" do
    #  embargo_release_date = 2.days.from_now
    #  # Because the JS will transform an unexpected input entry to the real
    #  # today (browser's date), and I want timecop to help
    #  embargo_release_date_formatted = embargo_release_date.strftime("%Y-%m-%d")
    #  login_as(user)
    #  visit('/concern/mock_curation_concerns/new')
    #  create_mock_curation_concern(
    #      'Embargo Release Date' => embargo_release_date_formatted,
    #      'Visibility' => 'visibility_embargo',
    #      'Contributors' => ['Dante'],
    #      'I Agree' => true
    #  )
    #
    #  page.assert_selector(
    #      ".embargo_release_date.attribute",
    #      text: embargo_release_date_formatted
    #  )
    #  page.assert_selector(
    #      ".permission.attribute",
    #      text: "Open Access"
    #  )
    #  noid = page.current_path.split("/").last
    #  logout
    #  visit("/show/#{noid}")
    #
    #  page.assert_selector('.contributor.attribute', text: 'Dante', count: 0)
    #  page.assert_selector('h1', text: "Object Not Available")
    #
    #  # Seconds are weeks
    #  begin
    #    Timecop.scale(60*60*24*7)
    #    sleep(1)
    #  ensure
    #    Timecop.scale(1)
    #  end
    #  visit("/show/#{noid}")
    #  expect(Time.now > embargo_release_date).to be_true
    #
    #  # With the embargo release date passed an anonymous user should be able
    #  # to see it.
    #  page.assert_selector('h1', text: "Object Not Available", count: 0)
    #end
  end

  #describe 'with user who has already agreed to the terms of service' do
  #  let(:agreed_to_terms_of_service) { true }
  #  it "displays the start uploading" do
  #    login_as(user)
  #    visit '/'
  #    click_link "Get Started"
  #    page.should have_content("What are you uploading?")
  #  end
  #
  #  it "allows me to directly create a senior thesis...then delete it", js: true do
  #    login_as(user)
  #    visit('/concern/senior_theses/new')
  #    page.assert_selector('.main-header h2', "Describe Your Thesis")
  #  end
  #end
  #
  #describe 'help request' do
  #  let(:agreed_to_terms_of_service) { true }
  #  # I want to test both JS mode and non-JS mode
  #  [true, false].each do |using_javascript|
  #    it "is available for users who are authenticated and agreed to ToS", js: using_javascript do
  #      login_as(user)
  #      visit('/')
  #      click_link("Get Started")
  #      click_link "Request Help"
  #      within("#new_help_request") do
  #        fill_in('How can we help you', with: "I'm trapped in a fortune cookie factory!")
  #        click_on("Let Us Know")
  #      end
  #      page.assert_selector('.notice', text: HelpRequestsController::SUCCESS_NOTICE)
  #    end
  #  end
  #end
  #
  #describe '+Add javascript behavior', js: true do
  #  let(:contributors) { ["D'artagnan", "Porthos", "Athos", 'Aramas'] }
  #  let(:agreed_to_terms_of_service) { true }
  #  let(:title) {"Somebody Special's Senior Thesis" }
  #  it 'handles contributor', js: true do
  #    login_as(user)
  #    visit('/concern/senior_theses/new')
  #    describe_your_thesis(
  #      "Title" => title,
  #      "Upload your thesis" => initial_file_path,
  #      "Contributors" => contributors,
  #      :js => true
  #    )
  #    page.should have_content(title)
  #    contributors.each do |contributor|
  #      page.assert_selector(
  #        '.senior_thesis.attributes .contributor.attribute',
  #        text: contributor
  #      )
  #    end
  #  end
  #
  #end
  #
  #describe 'I am logged in and request help' do
  #  let(:agreed_to_terms_of_service) { true }
  #  it "request help is registered" do
  #    login_as(user, scope: :user, run_callbacks: false)
  #    visit '/'
  #    click_link "Get Started"
  #    click_link "Request Help"
  #    within("#new_help_request") do
  #      fill_in('How can we help you', with: "I'm trapped in a fortune cookie factory!")
  #      click_on("Submit")
  #    end
  #    page.assert_selector('.notice', text: HelpRequestsController::SUCCESS_NOTICE)
  #  end
  #end
  #
  #describe 'file uploaded via different paths' do
  #  let(:agreed_to_terms_of_service) { true }
  #  let(:contributors) { ["Goethe"]}
  #  it "related file via senior_thesis#new and generic_file#new should be similar" do
  #    login_as(user)
  #    get_started
  #    classify_what_you_are_uploading('Senior Thesis')
  #    describe_your_thesis(
  #      "Title" => 'Senior Thesis',
  #      'Visibility' => 'Open Access',
  #      "Upload your thesis" => initial_file_path,
  #      "Assign DOI" => true,
  #      "Contributors" => contributors,
  #      "Button to click" => 'Create and Add Related Files...'
  #    )
  #    # While the title is different, the filenames should be the same
  #    add_a_related_file(
  #      "Title" => 'Related File',
  #      'Visibility' => 'University of Notre Dame',
  #      "Upload a related file" => initial_file_path
  #    )
  #
  #    page.assert_selector('h1', text: 'Senior Thesis')
  #
  #    page.assert_selector(
  #      '.senior_thesis.attributes .identifier.attribute',
  #      count: 1
  #    )
  #
  #    page.assert_selector(
  #      '.generic_file.attributes .title.attribute',
  #      text: "Related File",count: 1
  #    )
  #    page.assert_selector(
  #      '.generic_file.attributes .permission.attribute',
  #      text: "University of Notre Dame",count: 1
  #    )
  #    page.assert_selector(
  #      '.generic_file.attributes .title.attribute',
  #      text: "Senior Thesis",count: 1
  #    )
  #    page.assert_selector(
  #      '.generic_file.attributes .permission.attribute',
  #      text: "Open Access",count: 1
  #    )
  #    page.assert_selector(
  #      '.generic_file.attributes .filename.attribute',
  #      text: File.basename(initial_file_path),count: 2
  #    )
  #  end
  #end
  #describe 'with a user who has not agreed to terms of service' do
  #  let(:agreed_to_terms_of_service) { false }
  #  it "displays the terms of service page after authentication" do
  #    login_as(user)
  #    get_started
  #    agree_to_terms_of_service
  #    classify_what_you_are_uploading('Senior Thesis')
  #    describe_your_thesis
  #    path_to_view_thesis = view_your_new_thesis
  #    path_to_edit_thesis = edit_your_thesis
  #    view_your_updated_thesis
  #    view_your_dashboard
  #
  #    logout
  #    login_as(another_user)
  #    other_persons_thesis_is_not_in_my_dashboard
  #    i_can_see_another_users_open_resource(path_to_view_thesis)
  #    i_cannot_edit_to_another_users_resource(path_to_edit_thesis)
  #  end
  #end
  protected
  def get_started
    visit '/'
    click_link "Get Started"
  end

  def agree_to_terms_of_service
    within('#terms_of_service') do
      click_on("I Agree")
    end
  end

  def classify_what_you_are_uploading(concern)
    page.should have_content("What are you uploading?")
    within('#new_classify_concern') do
      select(concern, from: 'classify_concern_curation_concern_type')
      click_on("Continue")
    end
  end

  def describe_your_thesis(options = {})
    options['Title'] ||= initial_title
    options['Upload your thesis'] ||= initial_file_path
    options['Visibility'] ||= 'Private'
    options["Button to click"] ||= "Create Senior thesis"
    options["Contributors"] ||= ["Dante"]
    options["Content License"] ||= Sufia::Engine.config.cc_licenses.keys.first
    page.should have_content('Describe Your Thesis')
    # Without accepting agreement
    within('#new_senior_thesis') do
      fill_in("Title", with: options['Title'])
      attach_file("Upload your thesis", options['Upload your thesis'])
      choose(options['Visibility'])
      if options['Assign DOI']
        check('senior_thesis_assign_doi')
      end
      select(options['Content License'], from: 'Content License')
      within('.senior_thesis_contributor.multi_value') do
        contributors = [options['Contributors']].flatten.compact
        if options[:js]
          contributors.each_with_index do |contributor, i|
            within('.input-append:last') do
              fill_in('senior_thesis[contributor][]', with: contributor)
              click_on('Add')
            end
          end
        else
          fill_in('senior_thesis[contributor][]', with: contributors.first)
        end
      end
      click_on(options["Button to click"])
    end

    within('.alert.error') do
      page.should have_content('You must accept the contributor agreement')
    end
    page.should have_content("Describe Your Thesis")

    # With accepting agreement
    within('#new_senior_thesis') do
      # The system remembers the initial title
      find("#senior_thesis_title").value.should == options["Title"]
      attach_file("Upload your thesis", options['Upload your thesis'])
      check("I have read and accept the contributor licence agreement")
      click_on(options["Button to click"])
    end
  end

  def add_a_related_file(options = {})
    options['Title'] ||= initial_title
    options['Upload a file'] ||= initial_file_path
    options['Visibility'] ||= 'Private'
    within("form.new_generic_file") do
      fill_in("Title", with: options['Title'])
      attach_file("Upload a file", options['Upload a file'])
      choose(options['Visibility'])
      click_on("Attach to Senior Thesis")
    end
  end

  def view_your_new_thesis
    path_to_view_thesis  = page.current_path
    page.should have_content("Related Files")
    page.should have_content(initial_title)
    within(".generic_file.attributes") do
      page.should have_content(File.basename(initial_file_path))
    end

    return path_to_view_thesis
  end

  def edit_your_thesis
    click_on("Edit This Senior Thesis")
    edit_page_path = page.current_path
    within('.edit_senior_thesis') do
      fill_in("Title", with: updated_title)
      fill_in("Abstract", with: "Lorem Ipsum")
      click_on("Update Senior thesis")
    end
    return edit_page_path
  end
  def view_your_updated_thesis
    page.should have_content("Related Files")
    page.should have_content(updated_title)
    click_on("Back to Dashboard")
  end

  def view_your_dashboard
    search_term = "\"#{updated_title}\""

    within(".search-form") do
      fill_in("q", with: search_term)
      click_on("Go")
    end

    within('#documents') do
      page.should have_content(updated_title)
    end
    within('.alert.alert-info') do
      page.should have_content("You searched for: #{search_term}")
    end

    within('#facets') do
      # I call CSS/Dom shenannigans; I can't access 'Creator' link
      # directly and instead must find by CSS selector, validate it
      all('a.accordion-toggle').each do |elem|
        if elem.text == 'Creator'
          elem.click
        end
      end
      click_on(user.username)
    end
    within('.alert.alert-info') do
      page.should have_content("You searched for: #{search_term}")
    end
    within('.alert.alert-warning') do
      page.should have_content(user.username)
    end
  end

  def other_persons_thesis_is_not_in_my_dashboard
    visit "/dashboard"
    search_term = "\"#{updated_title}\""
    within(".search-form") do
      fill_in("q", with: search_term)
      click_on("Go")
    end
    within('#documents') do
      page.should_not have_content(updated_title)
    end
  end

  def i_can_see_another_users_open_resource(path_to_other_persons_resource)
    visit path_to_other_persons_resource
    page.should have_content(updated_title)
  end

  def i_cannot_edit_to_another_users_resource(path_to_other_persons_resource)
    visit path_to_other_persons_resource
    page.should_not have_content(updated_title)
  end
end
