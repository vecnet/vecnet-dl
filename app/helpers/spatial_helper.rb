module SpatialHelper
  def get_spatial_data(curation_concern)
    latitude=[]
    longitude=[]
    spatial_data={}
    unless curation_concern.spatials.empty?
      curation_concern.spatials.each do |spatial|
        latitude << spatial.latitude
        longitude << spatial.longitude
      end
    end
    spatial_data[:latitude]= (curation_concern.latitude.blank? ? [] : curation_concern.latitude) |latitude
    spatial_data[:longitude]= (curation_concern.longitude.blank? ? []:curation_concern.longitude) | longitude
    spatial_data
  end
end