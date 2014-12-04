Here are the list task that need to be taken for getting all geonames and hierarchy


* Run migrations (will create all new geoname table)
* Connect to postgres from command line in any server
    -- psql <database name>
    -- \c <database name>
* Copy geoname table dump into postgres
    -- Run this copy dump on any database
    --\copy geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from /path/to/allCountries.txt null as ''
* We create create dump for hierarchy or can run rake take to recreate them
    bx rake vecnet:location:trees  (this will take ver long time to create close to 300k records)
    OR Conviently you could copy the data from dump created in different environment
        psql <dbname> < <path/to/dump>
** Table migrations are complete

Adding hierarchy
This task only solrize generic file that have location not others

* rake vecnet:location:solrize_location_hierarchy
        -For each location, it finds geoname id fpath/to/dumppi
        -Get hierarchy from local database table
            if not available, it will query hierarchy and update our table and then return hierarchy
        - Index whole tree (as each section excluding earth)


Updating the table

Since geoname ids are allocated sequentially, we first find the maximum of the identifiers in the database and then only import the new records.

1) find the maximum in the database

    SELECT max(geonameid) from geoname;

2) filter the dump to only keep the new records. Here $MAXIMUM represents the id found in part 1

    cat allCountries.txt | awk '$1 > $MAXIMUM { print $0 }' > newCountries.txt

3) import the new records as done above.

    \copy geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from /path/to/newCountries.txt null as ''
