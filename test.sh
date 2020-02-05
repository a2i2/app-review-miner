#!/bin/sh

clear

EXPORT_DIR="`basename $0 .sh`_`date +%Y-%m-%d`_`date +%H.%M.%S`"
mkdir ${EXPORT_DIR}

echo "\n********************* AppMiner *********************"

echo "\n---[ Initialising database... ]---------------------\n"
ruby initDatabase.rb

echo "\n---[ Indexing apps... ]-----------------------------\n"
ruby indexApps_iOS.rb -c us -t 0 -g 0 -n 10 > ${EXPORT_DIR}/us_free_all.csv

echo "\n---[ Fetching reviews... ]--------------------------\n"
ruby getReviews_iOS.rb ${EXPORT_DIR}/*.csv

echo "\n***************** Scrape complete. *****************\n"