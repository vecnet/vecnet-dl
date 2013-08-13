class AddUidToUsers
  # On the transition to using pubtkt, we need to add the correct uid to each user already
  # in the database. Fortunately, there are only about 12 users.
  def migrate
    User.all.each do |user|
      if user_map.keys.include?(user.email)
        user.uid = user_map[user.email]
        user.save
      end
    end
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
      "banurekha.l@nd.edu" => 'lakshmib',
      "dbrower@nd.edu" => 'dbrower',
      "natalie.meyers@nd.edu" => 'nmeyers',
      "lawrence.selvy.1@nd.edu" => 'selvy'
    }
  end
end
