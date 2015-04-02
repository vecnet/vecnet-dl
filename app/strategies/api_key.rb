# pass the api key in the Api-Key header
Warden::Strategies.add(:apikey) do
  def valid?
    env['HTTP_API_KEY']
  end

  # we don't do the automatic redirects that
  # the reference pubtkt apache module does
  def authenticate!
    u = nil
    key = env['HTTP_API_KEY']
    u = User.find_from_apikey(key)
    logger.debug "Found user #{u} API KEY #{ticket}"
    u.nil? ? fail!("Invalid API Key") : success!(u)
  end

  # do not store the user in the session
  def store?
    false
  end
end
