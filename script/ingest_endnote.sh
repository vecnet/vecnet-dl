#!/bin/bash

# Ingest endnote citations.
# first argument is the ingest name
# second argmuent is the path to the endnote export file
# third argument is the path to the data PDF files

if [ $# -ne 3 ]; then
    echo "usage: $0  name  export_file  pdf_directory"
    exit 1
fi

import_name=$1
export ENDNOTE_FILE="$2"
export ENDNOTE_PDF_PATH="$3"

source /etc/profile.d/chruby.sh
chruby 2.0.0-p353

source /home/app/vecnet/current/script/get-env.sh
cd $RAILS_ROOT
bundle exec rake vecnet:import:endnote_conversion | tee "log/${import_name}.txt"
