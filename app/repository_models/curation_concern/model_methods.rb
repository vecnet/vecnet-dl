require 'hydra/model_methods'
module CurationConcern
  module ModelMethods
    extend ActiveSupport::Concern

    included do
      include Hydra::ModelMethods
      include Sufia::ModelMethods
    end

    # Adds depositor role to the rightsMetadata
    # Most important behavior: if the asset has a rightsMetadata datastream, this method will add +role+ to its edit group permissions.

    def apply_depositor_roles(depositor)
      rights_ds = self.datastreams["rightsMetadata"]
      roles = depositor.respond_to?(:roles) ? depositor.roles : []
      roles.each { |role| rights_ds.update_indexed_attributes([:edit_access, :group]=>role) unless rights_ds.nil? }
      return true
    end
  end
end
