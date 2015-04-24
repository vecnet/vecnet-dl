class UsageEvent < ActiveRecord::Base
  # `event` is the event that is being recorded.
  # The event field is a free-for-all. These events are currently defined.
  #
  #  `view`     for an html view of an item show page
  #  `download` for a download of an item's content. Does not include
  #             thumbnail downloads.
  #
  # `pid` is always the pid of the item being referenced. The pid may refer to
  # either an item in the DL or an external item. Do not assume it can be
  # looked up in Fedora.
  #
  # parent_pid is different from pid if this object is part of a
  # compound-object work. In that case, parent_pid is the pid for the main work
  # object. parent_pid will be null when pid refers to an item not in the DL.
  #
  # username is the uid of the pubtkt, if one be present.
  #
  # ip_address is the ip address of the client making this request
  # (in string form).
  #
  # event_time is the time this event happened. Since events are harvested from
  # logs, event_time is not necessarily the same as the AR created_at and
  # updated_at fields.
  attr_accessible :event, :pid, :parent_pid, :ip_address,
                  :username, :event_time
end
