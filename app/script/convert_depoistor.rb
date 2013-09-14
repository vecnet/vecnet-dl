class ConvertDepositor
  # Transform all objects depositor and permissions email to pubtkt user name
  #
  # Used to migrate the Fedora data from old user uid email to username
  # Usage:
  #
  # On rails console type
  #
  # a = ConvertDepositor.new
  # a.migrate(pid)

  #or to convert all objects user a.update_all_object
  #
  def migrate(pid)
    object= ActiveFedora::Base.find(pid, cast:true)
      if user_map.keys.include?(object.depositor)
        email=object.depositor
        object.depositor = user_map[email]
        object.save
        puts "Changed object #{object.pid} from depositor #{email} to #{user_map[email]}"
      end
      user_permissions={}
      object.permissions.select{|r| r[:type] == 'user'}.each do |r|
        user_permissions[r[:name]] = r[:access]
      end
      user_permissions.keys.each do |email|
        if user_map.keys.include?email
          rights_ds = object.datastreams["rightsMetadata"]
          rights_ds.update_indexed_attributes([:edit_access, :person]=>user_map[email])
        end
        puts "Changed object #{object.pid} user permission from user #{email} to #{user_map[email]}"
      end
      object.save!
  end

  def update_all_object
    assets = ActiveFedora::Base.find_with_conditions({},{:sort=>'pub_date desc', :rows=>2000, :fl=>'id, location_hierarchy_facet'})
    assets.each { |asset| migrate(asset['id']) }
  end

  # maps email to uid
  def user_map
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
