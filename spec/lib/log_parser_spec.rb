require 'spec_helper'
require 'stringio'
require 'log_parser'

describe LogParser do
  before do
    @lp = LogParser.new
    @sample_input = <<EOS
Started GET "/catalog/location/facet" for 1.2.3.4 at 2013-12-09 12:34:18 -0500
Processing by CatalogController#location_facet as */*
  Rendered layouts/vecnet.html.erb (5.3ms)
Completed 200 OK in 46ms (Views: 27.2ms | ActiveRecord: 0.0ms)
Started GET "/files/x059" for 192.168.4.16 at 2013-12-09 12:34:26 -0500
Processing by CurationConcern::GenericFilesController#show as */*
  Parameters: {"id"=>"x059"}
Pubtkt: Signature and ticket valid. User: jdoe, Groups: people
Completed 200 OK in 369ms (Views: 137.9ms | ActiveRecord: 0.0ms)
Started POST "/trackback/" for 192.168.4.16 at 2013-12-09 12:34:28 -0500

ActionController::RoutingError (No route matches [POST] "/files/x059c7400/trackback"):

Processing by ErrorsController#show as HTML
Completed 404 Not Found in 9ms (Views: 8.9ms | ActiveRecord: 0.0ms)
Started PUT "/" for 1.2.3.4 at 2013-12-09 12:35:02 -0500
Processing by CatalogController#index as */*
  Rendered layouts/vecnet.html.erb (5.6ms)
Completed 200 OK in 37ms (Views: 20.7ms | ActiveRecord: 1.8ms)
Started GET "/abc" for 1.2.3.4 at 2013-12-09 12:35:45 -0500
Processing by CatalogController#index as */*
Started GET "/def" for 1.2.3.4 at 2013-12-09 12:35:45 -0500
Processing by CatalogController#index as */*
  Rendered layouts/vecnet.html.erb (4.8ms)
Completed 200 OK in 29ms (Views: 39.2ms | ActiveRecord: 2.3ms)
  Rendered layouts/vecnet.html.erb (4.8ms)
Completed 200 OK in 59ms (Views: 39.2ms | ActiveRecord: 2.3ms)
EOS
  end

  it "parses the input correctly" do
    f = StringIO.new(@sample_input)
    r = []
    @lp.scan(f) { |item| r << item }
    r.should == [
      {method: "GET", path: "/catalog/location/facet", ip: "1.2.3.4", date: "2013-12-09 12:34:18 -0500", status: "200", duration: "46"},
      {method: "GET", path: "/files/x059", ip: "192.168.4.16", date: "2013-12-09 12:34:26 -0500", user: "jdoe", status: "200", duration: "369"},
      {method: "POST", path: "/trackback/", ip: "192.168.4.16", date: "2013-12-09 12:34:28 -0500", status: "404", duration: "9"},
      {method: "PUT", path: "/", ip: "1.2.3.4", date: "2013-12-09 12:35:02 -0500", status: "200", duration: "37"},
      {method: "GET", path: "/abc", ip: "1.2.3.4", date: "2013-12-09 12:35:45 -0500"},
      {method: "GET", path: "/def", ip: "1.2.3.4", date: "2013-12-09 12:35:45 -0500", status: "200", duration: "29"},
    ]
  end

end
