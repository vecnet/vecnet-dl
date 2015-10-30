--
select parent_pid,resource_type,count(*) as c
from usage_events
left outer join item_records on usage_events.parent_pid = item_records.pid
where event = 'download'
    and event_time >= date '2015-07-01'
    and event_time < date '2015-10-01'
group by parent_pid,resource_type
order by c desc;


-- view counts
select count(*) as c, parent_pid
from usage_events
where event = 'view'
    and event_time between date '2015-07-01' and date '2015-10-01'
group by parent_pid
order by c desc
limit 26;

-- ip address counts
select count(*) as c , ip_address , agent
from usage_events
where event_time between date '2015-07-01' and date '2015-10-01'
group by ip_address,agent
order by c desc
limit 26;

-- download counts
select count(*) as c, parent_pid
from usage_events
where event = 'download'
    and event_time between date '2015-07-01' and date '2015-10-01'
group by parent_pid
order by c desc
limit 25;

-- resource types
select count(*) as c , resource_type
from usage_events
left outer join item_records on usage_events.parent_pid = item_records.pid
where event_time between date '2015-07-01' and date '2015-10-01'
group by resource_type
order by c desc
limit 25;

-- users
select count(*) as c , username
from usage_events
where event_time between date '2015-07-01' and date '2015-10-01'
group by username
order by c desc;
