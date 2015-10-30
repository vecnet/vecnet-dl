VecNet Digital Library
======================

This post describes the addition of a GeoBlacklight discovery interface to the VecNet digital library.
The VecNet digital library provides resources useful to malaria researchers, and supports a malaria
modeling initiative.
It contains many kinds of content including articles; raster and vector GIS files; data tables; and simulation configuration files.

One of the most important items in malaria modeling is geographic location.
mosquitoe and malaria parasite species vary by location, so an important search to do is a geographic one.
Also, the GIS weather data is difficult to interact with without downloading the files and using a GIS program.
While we had added facets for location to the original search interface, it was not easy for researchers
to use. In 2014 we got a grant to add map-based search to the library.
After a few months of looking at possible methods, we decided to use GeoBlacklight as the interface.
Since the developers of the interface were new to blacklight and hydra, and because the original application was using an extremely old version of blacklight, we decided to make the discovery layer its own application.

This let the new developers to have a legacy-free code base to work with, and simplified their work since they would not need to run a fedora instance.

It also let us keep the original application with only minimal modifications.
Since the original application provides all the repository functionality, such as item deposit,
thumbnail generation, and usage tracking, this is important.
But it has become extremely complicated to understand and make changes to.

Instead, we run the new discovery interface along side the original application.
We even run both application on the same host name, so all the original paths still work.

The base application is a Hydra (sufia) program, but has become long-in-the-tooth. (since it was started by a direct fork from ScholarSphere in 2012.)

Incomming requests are routed to the appropriate application by nginx.
The two applications share the same authorization and session cookies.
Except for the CSS differences between the two applications, they function as a single program to the user.

[it is an interesting project since the blacklight interface was added in front of an existing hydra (sufia) based application, with the original application handling uploads and administrative tasks, and the geoblacklight front end providing a discovery interface.]


(figure of application architecture)

We decided to use this design to decouple the development of the new interface from understanding the legacy application.

The VecNet project is a endevor to support malaria research by providing online access
to two different malaria simulators.
Alongside this site, the digital library provides the data needed to support these simulations...weather, demographic, climate, moqauite properties, and a large collection of research articles and original datasets.




~~~~~~~~~~

It started in 201? as a general hydra front end. When ScholarSphere was publicly launched in November 2012, we immeadately took that as a base and made a fork to provide a self-deposit data repository.
It was later updated to use the sufia gem, and then the curate gem in 2014.
From all these migrations the code base has developed a large learning curve to understand. It is also a hydra application so requires a fair amount of infrastructure to run, such as
a solr core, a fedora instance, a redis server, and a database.

In 2014 the asutralian national data service awarded the XXX unit of James Cook University to develop a new map-based front end for the repository.

We decided the best way to handle this new development was to make the front end its own application. HydraConnect 2014 geoblaclkight, and used the EarthWorks code as a base.


vecnet has a unconventunal archicture in that it consists of a Hydra application AND a blacklight application.



+----------------------+             +-----------+
| GeoBlacklight        | ----------> | Solr core |
+----------------------+             +-----------+
                                           ^  periodic harvesting job
+----------------------+             +-----------+
| Sufia application    | ----------> | Solr core |
+----------------------+             +-----------+


The applications share the same domain, with nginx routing paths to the appropriate application.
They share the same session cookie.
Fortunately we already had an outside authentication system because of the shared environment
we were deployed in, so that was already accomplished in its own cookie.


The idea is to keep the discovery interface focused on only the interface, so that it is easy to replace every so often.
All the processing and management of the items is still done by the original sufia application.

An API was added to the original application to allow for easy progomatic harvesting of content.
Added a token authorization system to let the job harvest private records. (the interface still implements the same access control).

Defined JSON metadata format. simple API (maybe TOO simple)

(Disadis to provide downloads...?)

This approach has made many things easier.
First, we can index items which do not live in our fedora instance, and provide them as search results.
In VecNet's case that has been comupter simulations.
This flexibility in itself has been worth the effort.
But we also get a discovery application which lets the front end people develop without having to set up all the
extra pieces needed to run the repository services.

The main con is the complexity of having two applications run.
We needed to define a record export format, and we need to set up a cron job which also had credentials to access the restricted content.


https://github.com/vecnet/dl-discovery/
https://github.com/vecnet/deploy-dl
https://github.com/vecnet/vecnet-dl
https://github.com/ndlib/disadis

https://earthworks.stanford.edu/
https://github.com/geoblacklight/geoblacklight



This work was supported by the Bill and Melinda Gates Foundation and the Australian National Data Service.

