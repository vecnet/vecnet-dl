# Returns an array containing the vhost 'CoSign service' value and URL
Sufia.config do |config|
  config.id_namespace = "vecnet"
  config.fits_path = begin
    Rails.configuration.fits_path
  rescue NoMethodError
   "fits.sh"
  end
  config.fits_to_desc_mapping = begin
    Rails.configuration.fits_to_desc_mapping
  rescue NoMethodError => e
    { file_title: :title, file_author: :creator }
  end

  config.noid_template = '.reeddeeddk'

  config.max_days_between_audits = 7

  config.cc_licenses = {
      'Attribution 3.0 United States' => 'http://creativecommons.org/licenses/by/3.0/us/',
      'Attribution-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-sa/3.0/us/',
      'Attribution-NonCommercial 3.0 United States' => 'http://creativecommons.org/licenses/by-nc/3.0/us/',
      'Attribution-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nd/3.0/us/',
      'Attribution-NonCommercial-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-nd/3.0/us/',
      'Attribution-NonCommercial-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-sa/3.0/us/',
      'Public Domain Mark 1.0' => 'http://creativecommons.org/publicdomain/mark/1.0/',
      'CC0 1.0 Universal' => 'http://creativecommons.org/publicdomain/zero/1.0/',
      'All rights reserved' => 'All rights reserved'
  }

  config.cc_licenses_reverse = Hash[*config.cc_licenses.to_a.flatten.reverse]

  config.resource_types = {
      "Article" => "Article",
      "Audio" => "Audio",
      "Book" => "Book",
      "Conference Proceeding" => "Conference Proceeding",
      "Citation" => "Citation",
      "Dataset" => "Dataset",
      "Dataset: Climate/Weather" => "Dataset: Climate/Weather",
      "Dataset: Demography" => "Dataset: Demography",
      "Dataset: Entomological" => "Dataset: Entomological",
      "Dataset: Epidemiology / Public Health" => "Dataset: Epidemiology / Public Health",
      "Dataset: GIS" => "Dataset: GIS",
      "Dataset: Intervention data" => "Dataset: Intervention data",
      "Dataset: Model Input/Output Data" => "Dataset: Model Input/Output Data",
      "Dissertation" => "Dissertation",
      "Image" => "Image",
      "Journal" => "Journal",
      "Map or Cartographic Material" => "Map or Cartographic Material",
      "Poster" => "Poster",
      "Presentation" => "Presentation",
      "Project" => "Project",
      "Report" => "Report",
      "Research Paper" => "Research Paper",
      "Software or Program Code" => "Software or Program Code",
      "Thesis" => "Thesis",
      "Whitepaper" => "Whitepaper",
      "Video" => "Video",
      "Other" => "Other"
  }

  config.permission_levels = {
    "Choose Access"=>"none",
    "View/Download" => "read",
    "Edit" => "edit"
  }

  config.owner_permission_levels = {
    "Edit" => "edit"
  }

  config.queue = Sufia::Resque::Queue

  # Map hostnames onto Google Analytics tracking IDs
  if Rails.env.production?
    config.google_analytics_id = 'UA-40044476-1'
    config.google_analytics_domain = 'vecnet.org'
  end

end
