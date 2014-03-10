# How to generate usage logs for vecnet

1. Copy the appropriate log files onto your local machine.
2. run `ruby -Ilib ./script/scan_log_files.rb [list of log files to scan] > usage-201402`

Replace the [...] with a space separated list of the log file names to scan. Example:

    ruby -Ilib ./script/scan_log_files.rb production.log-201402* > usage-201402

A few caveats:

 * The log files are assumed to be gziped
 * No information on private objects (e.g. titles, geolocation, etc.) because there is no auth key to allow this (see lib/vecnet_usage.rb method `authCookie`)

