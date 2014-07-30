# Monkey patch the id service to query an external noid service
# when the following configuration is present:
#
# Rails.configuration.noid_server  # == "localhost:13001"
# Rails.configuration.noid_pool     # == "sufia"
#
require Sufia::Engine.root.join('lib/sufia/id_service')
require 'noid'
require 'noids_client'

module Sufia
  class IdService
    if Rails.configuration.noid_server
      @@service = ::NoidsClient::Connection.new(Rails.configuration.noid_server).get_pool(Rails.configuration.noid_pool)
      @@template = @@service.template.split('+').first
    else
      @@service = nil
      @@template = Sufia::Engine.config.noid_template rescue '.reeddeeddedk'
    end
    @@minter = ::Noid::Minter.new(:template => @@template)
    @@namespace = Sufia::Engine.config.id_namespace
    # seed with process id so that if two processes are running they do not come up with the same id.
    @@minter.seed($$)

    def self.valid?(identifier)
      # remove the fedora namespace since it's not part of the noid
      noid = identifier.split(":").last
      return @@minter.valid? noid
    end
    def self.mint
      while true
        pid = self.next_id
        break unless ActiveFedora::Base.exists?(pid)
      end
      return pid
    end
    protected
    def self.next_id
      id = @@service ? @@service.mint.first : @@minter.mint
      return  "#{@@namespace}:#{id}"
    end
  end
end
