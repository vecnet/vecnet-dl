class TemporalValidator < ActiveModel::Validator

  def validate(record)

    if nothing_present?(record.start_time,record.end_time)
      puts "no coordinates and everything good"
    elsif both_present?(record.start_time,record.end_time)
      puts "Both present Lat:#{record.start_time.inspect} long:#{record.end_time.inspect}"
      begin
        unless record.start_time.length.eql?(record.end_time.length)
          record.errors[:base] << "Invalid Spatial Data, Latitude and Longitude must be of same length"
        end
      rescue NoMethodError
        record.errors[:base] << "Invalid Spatial Data"
      end
    else
      puts "Only one available: Long- #{record.end_time}, Lat- #{record.start_time}"
      record.errors[:start_time] << "Invalid Spatial Data. start_time is blank" if record.start_time.blank?
      record.errors[:end_time] << "Invalid Spatial Data. end_time is blank" if record.end_time.blank?
    end
  end

  def both_present?(start_time, end_time)
    !start_time.blank? && !end_time.blank?
  end

  def nothing_present?(start_time, end_time)
    (start_time.blank?) && (end_time.blank?)
  end

end

