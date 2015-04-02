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
    if key && key.length > 0
      logger.debug "Found API KEY"
      u = User.find_by_api_key(key)
    end
    u.nil? ? fail!("Invalid API Key") : success!(u)
  end

  # do not store the user in the session
  def store?
    false
  end
end
