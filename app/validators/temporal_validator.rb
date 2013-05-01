class TemporalValidator < ActiveModel::Validator

  def validate(record)
    if both_present?(record.start_time,record.end_time)
      begin
        start_time=record.start_time.is_a?(Array) ? record.start_time : record.start_time.to_s.split()
        end_time=record.end_time.is_a?(Array) ? record.end_time : record.end_time.to_s.split()
        unless start_time.length.eql?(end_time.length)
          record.errors[:temporal] << "Invalid Time period Data, start_time and end time must be of same length"
        end
      rescue NoMethodError
        record.errors[:temporal] << "Invalid Time period Data"
      end
    end
  end

  def both_present?(start_time, end_time)
    !start_time.nil? && !end_time.nil?
  end

  def nothing_present?(start_time, end_time)
    (start_time.nil?) && (end_time.nil?)
  end

end

