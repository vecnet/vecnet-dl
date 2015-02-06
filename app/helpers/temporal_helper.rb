module TemporalHelper
  def get_temporal_data(curation_concern)
    times = []
    unless curation_concern.time_periods.empty?
      times = curation_concern.time_periods.map(&:to_s)
    end
    times
  end
end
