class SpatialValidator < ActiveModel::Validator

  def validate(record)

    if nothing_present?(record.latitude,record.longitude)
      #puts "no coordinates and everything good"
    elsif both_present?(record.latitude,record.longitude)
      #puts "Both present Lat:#{record.latitude.inspect} long:#{record.longitude.inspect}"
      begin
        latitude=record.latitude.is_a?(Array) ? record.latitude : record.latitude.to_s.split()
        longitude=record.longitude.is_a?(Array) ? record.longitude : record.longitude.to_s.split()
        #puts "Lat:#{latitude.reject(&:empty?).length}, long:#{longitude.reject(&:empty?).length}"
        unless latitude.reject(&:empty?).length.eql?(longitude.reject(&:empty?).length)
          record.errors[:spatials] << "Invalid Spatial Data, both Latitude and Longitude must have value"
        end
      rescue NoMethodError
        record.errors[:base] << "Invalid Spatial Data"
      end
    else
      #puts "Only one available: Long- #{record.longitude}, Lat- #{record.latitude}"
      if record.latitude.blank?
        record.errors[:latitude] << "Invalid Spatial Data. latitude is blank"
        record.errors[:spatials] << "Invalid Spatial Data. latitude is blank"
      elsif
        record.errors[:longitude] << "Invalid Spatial Data. longitude is blank"
        record.errors[:spatials] << "Invalid Spatial Data. longitude is blank"
      end


    end
  end

  def both_present?(latitude, longitude)
    !latitude.blank? && !longitude.blank?
  end

  def nothing_present?(latitude, longitude)
    (latitude.blank?) && (longitude.blank?)
  end

end

