# This is a WIP. do expect it to do anything.
#
# we now need to decode all the object ids and collect their metadata
# rather than start up the rails application, post job to queue and let a
# worker do this
require 'resque'

Resque.redis = "localhost:6379/vecnet:"

# totally bogus that sufia abstracts its own job parameters system on top
# of resque.
class MarshaledJob
end
class CharacterizeJob
    attr_accessor :generic_file_id
end

job = CharacterizeJob.new
job.generic_file_id = "und:pc289j050"
::Resque.enqueue_to "characterize", MarshaledJob, Marshal.dump(job)

