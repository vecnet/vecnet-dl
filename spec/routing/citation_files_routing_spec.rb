require 'spec_helper'

describe 'citation files routing' do
  let(:parent_id) { '1a2b3c' }
  let(:child_id) { '1a2b3c4d5e' }

  it "routes GET /concern/related_files/:id" do
    expect(
      get: "/concern/citation_files/#{child_id}"
    ).to(
      route_to(
        controller: "curation_concern/citation_files",
        action: "show",
        id: child_id
      )
    )
  end

  it "routes GET /concern/related_files/:id/edit" do
    expect(
      get: "/concern/citation_files/#{child_id}/edit"
    ).to(
      route_to(
        controller: "curation_concern/citation_files",
        action: "edit",
        id: child_id
      )
    )
  end

  it "routes GET /concern/related_files/:id" do
    expect(
      put: "/concern/citation_files/#{child_id}"
    ).to(
      route_to(
        controller: "curation_concern/citation_files",
        action: "update",
        id: child_id
      )
    )
  end

  it "routes DELETE /concern/container/:parent_id/related_files" do
    expect(
      delete: "/concern/citation_files/#{child_id}"
    ).to(
      route_to(
        controller: "curation_concern/citation_files",
        action: "destroy",
        id: child_id
      )
    )
  end

end
