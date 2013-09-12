Here are the list task that need to be taken for getting all geonames and hierarchy


* Run migrations (will create all new geoname table)
* Copy geoname table dump into postgres
    -- Run this copy dump on any database
    --\copy geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from /path/to/allCountries.txt null as '';
* We create create dump for hierarchy or can run rake take to recreate them
    bx rake vecnet:location:trees  (this will take ver long time to create close to 300k records)
** Table migrations are complete

Adding hierarchy
This task only solrized generic file that have location not others

* rake vecnet:location:solrize_location_hierarchy
        -For each location, it finds geoname id from search api
        -Get hierarchy from local database table
            if not available, it will query hierarchy and update our table and then return hierarchy
        - Index whole tree (as each section excluding earth)