class ConvertDepositor
  # Transform all objects depositor and permissions email to pubtkt user name
  #
  # Used to migrate the Fedora data from old user uid email to username
  # Usage:
  #
  # On rails console type
  #
  # ConvertDepositor.all_repo_objects
  #

  def self.try_attribute(obj, name)
    obj.send(name)
  rescue NoMethodError
    nil
  end

  def self.migrate(pid)
    object= ActiveFedora::Base.find(pid, cast:true)
    dirty=self.migrate_user_permission(object)|self.migrate_depositor(object)

    if dirty
      puts "Need to save: #{dirty.inspect}"
      begin
        object.save!
      rescue    Exception=>e
        logger.error "Error occurred during save, either depositor or user permission changed for object : #{object.id}"
        logger.error "#{e.inspect}"
        puts e.inspect
      end
    end
  end

  def self.migrate_depositor(object)
    if self.try_attribute(object, :depositor)
      if self.user_map.keys.include?(object.depositor)
        email=object.depositor
        object.depositor = user_map[email]
        puts "Changed object #{object.pid} from depositor #{email} to #{user_map[email]}"
        logger.error "Changed object #{object.pid} from depositor #{email} to #{user_map[email]}"
        return true
      end
    end
    return false
  end

  def self.migrate_user_permission(object)
    if self.try_attribute(object, :permissions)
      user_permissions={}
      object.permissions.select{|r| r[:type] == 'user'}.each do |r|
        user_permissions[r[:name]] = r[:access]
      end
      user_permissions.keys.each do |email|
        if self.user_map.keys.include?email
          rights_ds = object.datastreams["rightsMetadata"]
          rights_ds.update_indexed_attributes([:edit_access, :person]=>user_map[email])
          puts "Changed object #{object.pid} user permission from user #{email} to #{user_map[email]}"
          logger.error "Changed object #{object.pid} user permission from user #{email} to #{user_map[email]}"
          return true
        end
      end
    end
    return false
  end

  def self.all_repo_objects
    assets = ActiveFedora::Base.find_with_conditions({},{:sort=>'pub_date desc', :rows=>2000, :fl=>'id, location_hierarchy_facet'})
    logger.debug("Total Object in repo: #{assets.count}")
    assets.each { |asset| self.migrate(asset['id']) }
  end

  # maps email to uid
  def self.user_map
    {
        'rick.johnson@nd.edu' => 'rjohnso5',
        'ladwig.1@nd.edu' => 'ladwig',
        "michelle.barker1@jcu.edu.au" => 'mbarker',
        "robert.farlow@yahoo.com" => 'farlow',
        "james.domingo@nd.edu" => 'domingo',
        "tom.burkot@jcu.edu.au" => 'burkot',
        "tanya.russell@jcu.edu.au" => 'trussell',
        "marianne.sinka@zoo.ox.ac.uk" => 'sinka' ,
        "banurekha.l@nd.edu" => 'blakshmi',
        "dbrower@nd.edu" => 'dbrower',
        "natalie.meyers@nd.edu" => 'nmeyers',
        "lawrence.selvy.1@nd.edu" => 'selvy'
    }
  end
end
