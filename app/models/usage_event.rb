class UsageEvent < ActiveRecord::Base
  # `event` is the event that is being recorded.
  # The event field is a free-for-all. These events are currently defined.
  #
  #  `view`     for an html view of an item show page
  #  `download` for a download of an item's content. Does not include
  #             thumbnail downloads.
  #  `search`
  #
  # `pid` is always the pid of the item being referenced. The pid may refer to
  # either an item in the DL or an external item. Do not assume it can be
  # looked up in Fedora.
  #
  # `parent_pid` is different from pid if this object is part of a
  # compound-object work. In that case, parent_pid is the pid for the main work
  # object. parent_pid will be null when pid refers to an item not in the DL.
  #
  # `username` is the uid of the pubtkt, if one be present.
  #
  # `ip_address` is the ip address of the client making this request
  # (in string form).
  #
  # `event_time` is the time this event happened. Since events are harvested from
  # logs, event_time is not necessarily the same as the AR created_at and
  # updated_at fields.
  attr_accessible :event, :pid, :parent_pid, :ip_address,
                  :username, :event_time, :agent

  def self.resource_reporting(start=nil, stop=nil)
    sql = %(
      SELECT resource_type, event, count(*) AS count
      FROM usage_events
      LEFT OUTER JOIN item_records ON usage_events.parent_pid = item_records.pid)
    start = self.format_date(start)
    stop = self.format_date(stop)
    if start && stop
      sql += " WHERE event_time BETWEEN \"#{start}\" AND \"#{stop}\""
    elsif start
      sql += " WHERE event_time >= \"#{start}\""
    elsif stop
      sql += " WHERE event_time <= \"#{stop}\""
    end
    sql += " GROUP BY resource_type, event;"
    result = ActiveRecord::Base.connection.execute(sql)
  end

  def self.format_date(d)
    return d.strftime("%Y-%m-%d") if d.is_a?(Date)
    return d if d =~ /\A\d{4}-\d{1,2}-\d{1,2}\Z/
    nil
  end
end
