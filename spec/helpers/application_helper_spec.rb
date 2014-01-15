require 'spec_helper'

describe ApplicationHelper do
  it 'has #sufia as a "monkey-patch" for sufia gem' do
    expect(helper.sufia).to eq(helper)
  end

  it 'has #default_page_title' do
    expect(helper.default_page_title).to(
      eq("#{controller_name.titleize} // VecNet Digital Library")
    )
  end

  it 'has #curation_concern_page_title' do
    expect(helper.curation_concern_page_title(GenericFile.new)).to(
      eq("New Generic File // VecNet Digital Library")
    )
  end

  describe '#curation_concern_attribute_to_html' do
    it 'handles an array by rendering one <dd> per element' do
      collection = ["<h2>", "Johnny Tables"]
      object = double('curation_concern', things: collection)

      expect(helper.curation_concern_attribute_to_html(object, :things, "Weird")).to(
        eq("<tr><th>Weird</th>\n<td><ul class='tabular'><li class=\"attribute things\">&lt;h2&gt;</li>\n<li class=\"attribute things\">Johnny Tables</li>\n</ul></td></tr>")
      )
    end
    it 'handles a string by rendering one <dd>' do
      collection = "Tim"
      object = double('curation_concern', things: collection)

      expect(helper.curation_concern_attribute_to_html(object, :things, "Weird")).to(
        eq("<tr><th>Weird</th>\n<td><ul class='tabular'><li class=\"attribute things\">Tim</li>\n</ul></td></tr>")
      )
    end
    it 'returns a '' for a nil value' do
      collection = nil
      object = double('curation_concern', things: collection)

      expect(helper.curation_concern_attribute_to_html(object, :things, "Weird")).to(
        eq("")
      )
    end
    it 'returns a '' for an empty array' do
      collection = []
      object = double('curation_concern', things: collection)

      expect(helper.curation_concern_attribute_to_html(object, :things, "Weird")).to(
        eq("")
      )
    end
  end

  describe '#bootstrap_navigation_element' do
    let(:path) { '/hello/world' }
    let(:name) { "Link Name"}
    let(:expected_css_matcher) { 'li.active a[href="#"]' }
    it 'disables the navigation link to the active page' do
      helper.should_receive(:current_page?).with(path).and_return(true)
      expect(helper.bootstrap_navigation_element(name, path)).
        to have_tag(expected_css_matcher)
    end
    it 'does not disable a navigation link that is not the active page' do
      helper.should_receive(:current_page?).with(path).and_return(false)
      expect(helper.bootstrap_navigation_element(name, path)).
        to_not have_tag(expected_css_matcher)
    end
  end

  describe '#link_to_edit_permissions' do
    let(:solr_document) { {read_access_group_t: access_policy } }
    let(:user) { FactoryGirl.create(:user) }
    let(:curation_concern) {
      FactoryGirl.create_generic_file(:collection, user, nil, visibility: visibility)
    }
    let(:visibility) { nil }
    let(:access_policy) { nil }
    describe 'with a "registered" access group' do
      let(:expected_label) { "Vecnet Users" }
      let(:visibility) { 'psu' } # Can we change this?
      let(:access_policy) { 'registered' }
      it 'renders a Vecnet Users label' do
        rendered = helper.link_to_edit_permissions(curation_concern, solr_document)
        expect(rendered).to(
          have_tag("a#permission_#{curation_concern.to_param}") {
            with_tag("span.label.label-info", with: {title: expected_label }, text: expected_label)
          }
        )
      end
    end
    describe 'with a "public" access group' do
      let(:expected_label) { "Global Access" }
      let(:access_policy) { 'public' }
      let(:visibility) { 'open'}
      it 'renders an "Open Access" label' do
        rendered = helper.link_to_edit_permissions(curation_concern, solr_document)
        expect(rendered).to(
          have_tag("a#permission_#{curation_concern.to_param}") {
            with_tag("span.label.label-success", with: {title: expected_label }, text: expected_label)
          }
        )
      end
    end
    describe 'with a mixed "public registered" access group' do
      # This test is purely speculative to the appropriate labeling behavior and
      # does not account for whether the document is truly accessable; I suppose
      # I'm persisting hash drive development via a Solr document
      let(:expected_label) { "Global Access" }
      let(:access_policy) { 'public registered' }
      it 'renders an "Open Access" label' do
        rendered = helper.link_to_edit_permissions(curation_concern, solr_document)
        expect(rendered).to(
          have_tag("a#permission_#{curation_concern.to_param}") {
            with_tag("span.label.label-success", with: {title: expected_label }, text: expected_label)
          }
        )
      end
    end
    describe 'without an access group' do
      let(:expected_label) { "Private" }
      let(:access_policy) { nil }
      let(:visibility) { 'restricted' }
      it 'renders an "Private" label' do
        rendered = helper.link_to_edit_permissions(curation_concern, solr_document)
        expect(rendered).to(
          have_tag("a#permission_#{curation_concern.to_param}") {
            with_tag("span.label.label-important", with: {title: expected_label }, text: expected_label)
          }
        )
      end
    end
  end
end
