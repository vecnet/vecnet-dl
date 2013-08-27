#!/bin/sh

echo `date`
endnote_file=/opt/endnote/<endnotefilename>
path_for_full_text=/opt/citation_files:/opt/citation_files/<endnotefilename>
cd /home/app/vecnet/current
RAILS_ENV=$1 bundle exec rake vecnet:import:endnote_conversion ENDNOTE_FILE=endnote_file ENDNOTE_PDF_PATH=path_for_full_text
