# spec/support/fixture_helpers.rb
module FixtureHelpers
  def find_or_create_file_fixtures_with_user(user)
    attributes_array = [  {title:"Fake Document Title", resource_type: "Article",subject: %w"lorem ipsum dolor sit amet",visibility:'open'},
                          {title:"Fake Audio Title", resource_type: ["Audio","other"],subject: %w"consectetur adipisicing elit",visibility:'open'},
                          {title:"Fake Dataset Title", resource_type: "dataset",subject: %w"lorem ipsum dolor sit amet",visibility:'open'},
                          {title:"Fake Private Title", resource_type: "Article",visibility:'restricted'}
                        ]
    fixtures = []
    collection= FactoryGirl.create_curation_concern(:collection, user)
    attributes_array.each {|attributes| fixtures << FactoryGirl.create_generic_file(collection, user, nil,attributes) }
    return fixtures
  end
end

