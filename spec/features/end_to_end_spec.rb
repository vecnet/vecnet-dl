require 'spec_helper'
require 'selenium-webdriver'

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
  let(:admin_user) { FactoryGirl.create(:user, group_list: ['dl_librarian'], agreed_to_terms_of_service: true) }
  let(:prefix) { Time.now.strftime("%Y-%m-%d-%H-%M-%S-%L") }
  let(:initial_title) { "#{prefix} Something Special" }
  let(:initial_resource_type) { "Article" }
  let(:initial_file_path) { __FILE__ }
  let(:updated_title) { "#{prefix} Another Not Quite" }
  let(:updated_file_path) { Rails.root.join('app/controllers/application_controller.rb').to_s }
  let(:public_title) { 'Fake title with public access' }
  let(:restricted_title) {'Fake Article with restricted access'}

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

  describe 'with user who sign in' do
    before do
      login_as(user)
      visit '/'
      click_link user.name
    end

    it 'allows me to create a mock curation concern' do
      page.should have_css('.dropdown-menu', visible: true)
      click_upload_file
      page.assert_selector('h1', :text => 'Create and Apply Metadata', :visible => true)
    end
  end

  describe 'with user who sign in' do
    it 'saves mock curation concern inputs when data is valid' do
      Capybara.current_driver = :selenium
      login_as(user)
      visit new_classify_concern_path
      create_mock_curation_concern(
          'Visibility' => 'visibility_restricted',
          'Title' => 'Bogus Title'
      )
      #puts "Capybara Session:#{Capybara.session.inspect}"
      within('#documents') do
        page.should have_content('Bogus Title')
      end
    end
    it "a public item is visible when logged out" , js: true do
      Capybara.current_driver = :selenium
      login_as(user)
      visit new_classify_concern_path
      create_mock_curation_concern(
          'Visibility' => 'visibility_open',
          'Contributors' => ['Dante'],
          'Title' => public_title
      )
      within('#documents') do
        page.should have_content('Fake title with public access')
      end
      logout
      visit '/'
      within('.search-form') do
        fill_in "Search Digital Library", with: public_title
        click_button("search-submit-header")
      end
      page.should have_content "1 to 1 of 1"
      click_link public_title
      page.should have_content "Download"
      page.should_not have_content "Edit"
    end
  end

  #describe '+Add javascript behavior', js: true do
  #  let(:contributors) { ["D'artagnan", "Porthos", "Athos", 'Aramas'] }
  #  let(:agreed_to_terms_of_service) { true }
  #  let(:title) {"Somebody Special's Senior file" }
  #  it 'handles contributor', js: true do
  #    login_as(user)
  #    visit('/concern/generic_file/new')
  #    describe_your_file(
  #      "Title" => title,
  #      "Upload your file" => initial_file_path,
  #      "Contributors" => contributors,
  #      :js => true
  #    )
  #    page.should have_content(title)
  #    contributors.each do |contributor|
  #      page.assert_selector(
  #        '.senior_file.attributes .contributor.attribute',
  #        text: contributor
  #      )
  #    end
  #  end
  #
  #end

  describe 'with a regular user' do
    it "create and view file in my dashboard" do
      login_as(user)
      visit new_classify_concern_path
      describe_your_file({'Title'=>initial_title, 'Visibility' => 'visibility_open'})
      path_to_view_file = view_your_new_file(initial_title)
      path_to_edit_file = edit_your_file(initial_title)
      view_your_updated_file
      view_your_dashboard
      logout(user)

      login_as(another_user)
      page.assert_selector('h2', :text => 'My Dashboard', :visible => true)
      other_persons_file_is_not_in_my_dashboard(updated_title,another_user)
      i_can_see_another_users_open_resource(path_to_view_file)
      i_cannot_edit_to_another_users_resource(path_to_edit_file)
    end
  end

  describe 'with a admin user' do
    it "create and view all file in admin dashboard" do
      login_as(user)
      visit new_classify_concern_path
      describe_your_file({'Title'=>restricted_title})
      path_to_view_file=view_your_new_file(restricted_title)
      logout(user)

      login_as(admin_user)
     # page.assert_selector('h2', :text => 'My Dashboard', :visible => true)
      other_persons_file_is_not_in_my_dashboard(restricted_title, admin_user)
      #save_and_open_page
      visit_admin_dashboard
      view_admin_dashboard
      admin_can_see_another_users_restricted_resource(path_to_view_file)
      admin_can_edit_another_users_resource
    end
  end

  protected

  # Quick access to Warden::Proxy.
  def warden
    @warden ||= begin
      manager = Warden::Manager.new(nil, &Rails.application.config.middleware.detect{|m| m.name == 'Warden::Manager'}.block)
      @request.env['warden'] = Warden::Proxy.new(@request.env, manager)
    end
  end

  def create_mock_curation_concern(options = {})
    options['Title'] ||= initial_title
    options['Upload your file'] ||= initial_file_path
    options['Visibility'] ||= 'visibility_restricted'
    options["Button to click"] ||= "Save"
    options["Contributors"] ||= ["Dante"]
    options["Content License"] ||= Sufia::Engine.config.cc_licenses.keys.first
    options["Contributors"] ||= ["Dante"]
    options["Resource Type"] ||= Sufia::Engine.config.resource_types.keys.first

    page.should have_content('Create and Apply Metadata')
    within('#new_generic_file') do
      fill_in("generic_file_title", with: options['Title'])
      #attach_file("generic_file_file", options['Upload your file'])
      choose(options['Visibility'])
      select(options['Content License'], from: I18n.translate('sufia.field_label.rights'))
      select(options['Resource Type'], from: "Resource type")
      fill_out_form_multi_value_for('contributor', with: options['Contributors'])
      click_on(options["Button to click"])
    end
  end

  def describe_your_file(options = {})
    options['Title'] ||= initial_title
    options['Upload your file'] ||= initial_file_path
    options['Visibility'] ||= 'Private'
    options["Button to click"] ||= "Save"
    options["Contributors"] ||= ["Dante"]
    options["Content License"] ||= Sufia::Engine.config.cc_licenses.keys.first
    options["Resource Type"] ||= initial_resource_type

    page.should have_content('Create and Apply Metadata')

    within('#new_generic_file') do
      fill_in("generic_file_title", with: options['Title'])
      attach_file("generic_file_file", options['Upload your file'])
      choose(options['Visibility'])
      select(options['Content License'], from: "Rights")
      select(options['Resource Type'], from: "Resource type")
      within('div.generic_file_contributor.multi_value') do
        contributors = [options['Contributors']].flatten.compact
        if options[:js]
          contributors.each_with_index do |contributor, i|
            within('.input-append:last') do
              fill_in('generic_file[contributor][]', with: contributor)
              click_on('Add')
            end
          end
        else
          fill_in('generic_file[contributor][]', with: contributors.first)
        end
      end
      click_on(options["Button to click"])
    end
  end

  protected

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
    page.should have_css('.user-menu', visible: true)
    within(".user-menu") do
      click_on 'Upload a file'
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
      click_on("Attach to Senior file")
    end
  end

  def view_your_new_file(title_to_look_for)
    visit '/dashboard'
    page.should have_content(title_to_look_for)
    click_link title_to_look_for
    path_to_view_file  = page.current_path
    page.should have_content("Description")
    page.should have_content(title_to_look_for)
    within(".generic_file.characterize") do
      page.should have_content("Filename: #{File.basename(initial_file_path)}")
    end

    return path_to_view_file
  end

  def edit_your_file(title_to_edit)
    visit '/dashboard'
    page.should have_content(title_to_edit)
    click_link title_to_edit
    click_on("Edit")
    edit_page_path = page.current_path
    within('.edit_generic_file') do
      fill_in("generic_file_title", with: updated_title)
      fill_in("generic_file_description", with: "Lorem Ipsum")
      click_on("Save")
    end
    return edit_page_path
  end
  def view_your_updated_file
    page.should have_content("Edit #{updated_title}")
    click_on("Cancel")
    page.assert_selector('h2', :text => 'My Dashboard', :visible => true)
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
        if elem.text == 'Resource Type'
          elem.click
        end
      end
      click_on(initial_resource_type)
    end
    within('.alert.alert-info') do
      page.should have_content("You searched for: #{search_term}")
    end
    within('.alert.alert-warning') do
      page.should have_content(initial_resource_type)
    end
  end

  def other_persons_file_is_not_in_my_dashboard(search_title,logged_user)
    visit "/dashboard"
    search_term = "\"#{search_title}\""

    within(".search-form") do
      fill_in("q", with: search_term)
      click_on("Go")
    end
    page.should have_selector('a#username', :text => logged_user.name)
    within('#documents') do
      page.should_not have_content(search_title)
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

  def admin_can_see_another_users_restricted_resource(path_to_other_persons_resource)
    visit path_to_other_persons_resource
    page.should have_content(restricted_title)
  end

  def admin_can_edit_another_users_resource
#Assuming there is only one resource available
    visit '/admin_dashboard'
    page.assert_selector('h2', :text => 'Admin Dashboard', :visible => true)
    page.should have_content(restricted_title)
    page.should have_selector('a.itemedit')
    find(:css, ".itemedit", :visible=>true).click
    page.should have_content("Edit #{restricted_title}")
    click_on("Cancel")
  end

  def visit_admin_dashboard
    puts "Admin user: #{admin_user.inspect}, groups_list:#{admin_user.group_list}, groups:#{admin_user.groups}"

    click_link(admin_user.name)
    page.should have_css('.user-menu', visible: true)
    within(".user-menu") do
      click_link 'Admin Dashboard'
    end
    page.assert_selector('h2', :text => 'Admin Dashboard', :visible => true)
  end

  def view_admin_dashboard
    search_term = "\"#{restricted_title}\""

    within(".search-form") do
      fill_in("q", with: search_term)
      click_on("Go")
    end
    within('#documents') do
      page.should have_content(restricted_title)
    end
    within('.alert.alert-info') do
      page.should have_content("You searched for: #{search_term}")
    end

    within('#facets') do
      # I call CSS/Dom shenannigans; I can't access 'Creator' link
      # directly and instead must find by CSS selector, validate it
      all('a.accordion-toggle').each do |elem|
        if elem.text == 'Resource Type'
          elem.click
        end
      end
      click_on(initial_resource_type)
    end
    within('.alert.alert-info') do
      page.should have_content("You searched for: #{search_term}")
    end
    within('.alert.alert-warning') do
      page.should have_content(initial_resource_type)
    end
  end
end
