module TemporalHelper
  def get_temporal_data(curation_concern)
    start_time=[]
    end_time=[]
    temporal_data={}
    unless curation_concern.temporals.empty?
      curation_concern.temporals.each do |temporal|
        start_time << temporal.start_time
        end_time << temporal.end_time
      end
    end
    temporal_data[:start_time]= (curation_concern.start_time.blank? ? [] : curation_concern.start_time) |start_time
    temporal_data[:end_time]= (curation_concern.end_time.blank? ? []:curation_concern.end_time) | end_time
    temporal_data
  end
end