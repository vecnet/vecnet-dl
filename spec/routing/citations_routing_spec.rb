require 'spec_helper'

describe 'citations routing' do
  let(:parent_id) { '1a2b3c' }
  let(:child_id) { '1a2b3c4d5e' }

  it "routes GET /concern/related_files/:id" do
    expect(
      get: "/concern/citations/#{child_id}"
    ).to(
      route_to(
        controller: "curation_concern/citations",
        action: "show",
        id: child_id
      )
    )
  end

  it "routes GET /concern/related_files/:id/edit" do
    expect(
      get: "/concern/citations/#{child_id}/edit"
    ).to(
      route_to(
        controller: "curation_concern/citations",
        action: "edit",
        id: child_id
      )
    )
  end

  it "routes GET /concern/related_files/:id" do
    expect(
      put: "/concern/citations/#{child_id}"
    ).to(
      route_to(
        controller: "curation_concern/citations",
        action: "update",
        id: child_id
      )
    )
  end


  it "routes DELETE /concern/container/:parent_id/related_files" do
    expect(
      delete: "/concern/citations/#{child_id}"
    ).to(
      route_to(
        controller: "curation_concern/citations",
        action: "destroy",
        id: child_id
      )
    )
  end

end
