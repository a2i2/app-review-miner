#!/bin/sh

clear

EXPORT_DIR="`basename $0 .sh`_`date +%Y-%m-%d`_`date +%H.%M.%S`"
mkdir ${EXPORT_DIR}

echo "\n********************* AppMiner *********************"

echo "\n---[ Initialising database... ]---------------------\n"
ruby initDatabase.rb

echo "\n---[ Indexing apps... ]-----------------------------\n"
ruby indexApps_iOS.rb -c us -t 0 -g 0 -n 400 > ${EXPORT_DIR}/us_free_all.csv
ruby indexApps_iOS.rb -c us -t 0 -g 1 -n 400 > ${EXPORT_DIR}/us_free_books.csv
ruby indexApps_iOS.rb -c us -t 0 -g 2 -n 400 > ${EXPORT_DIR}/us_free_business.csv
ruby indexApps_iOS.rb -c us -t 0 -g 3 -n 400 > ${EXPORT_DIR}/us_free_catalogs.csv
ruby indexApps_iOS.rb -c us -t 0 -g 4 -n 400 > ${EXPORT_DIR}/us_free_education.csv
ruby indexApps_iOS.rb -c us -t 0 -g 5 -n 400 > ${EXPORT_DIR}/us_free_entertainment.csv
ruby indexApps_iOS.rb -c us -t 0 -g 6 -n 400 > ${EXPORT_DIR}/us_free_finance.csv
ruby indexApps_iOS.rb -c us -t 0 -g 7 -n 400 > ${EXPORT_DIR}/us_free_games.csv
ruby indexApps_iOS.rb -c us -t 0 -g 8 -n 400 > ${EXPORT_DIR}/us_free_health.csv
ruby indexApps_iOS.rb -c us -t 0 -g 9 -n 400 > ${EXPORT_DIR}/us_free_lifestyle.csv
ruby indexApps_iOS.rb -c us -t 0 -g 10 -n 400 > ${EXPORT_DIR}/us_free_medical.csv
ruby indexApps_iOS.rb -c us -t 0 -g 11 -n 400 > ${EXPORT_DIR}/us_free_music.csv
ruby indexApps_iOS.rb -c us -t 0 -g 12 -n 400 > ${EXPORT_DIR}/us_free_navigation.csv
ruby indexApps_iOS.rb -c us -t 0 -g 13 -n 400 > ${EXPORT_DIR}/us_free_news.csv
ruby indexApps_iOS.rb -c us -t 0 -g 14 -n 400 > ${EXPORT_DIR}/us_free_newsstand.csv
ruby indexApps_iOS.rb -c us -t 0 -g 15 -n 400 > ${EXPORT_DIR}/us_free_photo.csv
ruby indexApps_iOS.rb -c us -t 0 -g 16 -n 400 > ${EXPORT_DIR}/us_free_productivity.csv
ruby indexApps_iOS.rb -c us -t 0 -g 17 -n 400 > ${EXPORT_DIR}/us_free_reference.csv
ruby indexApps_iOS.rb -c us -t 0 -g 18 -n 400 > ${EXPORT_DIR}/us_free_social_networking.csv
ruby indexApps_iOS.rb -c us -t 0 -g 19 -n 400 > ${EXPORT_DIR}/us_free_sports.csv
ruby indexApps_iOS.rb -c us -t 0 -g 20 -n 400 > ${EXPORT_DIR}/us_free_travel.csv
ruby indexApps_iOS.rb -c us -t 0 -g 21 -n 400 > ${EXPORT_DIR}/us_free_utilities.csv
ruby indexApps_iOS.rb -c us -t 0 -g 22 -n 400 > ${EXPORT_DIR}/us_free_weather.csv

ruby indexApps_iOS.rb -c us -t 1 -g 0 -n 400 > ${EXPORT_DIR}/us_paid_all.csv
ruby indexApps_iOS.rb -c us -t 1 -g 1 -n 400 > ${EXPORT_DIR}/us_paid_books.csv
ruby indexApps_iOS.rb -c us -t 1 -g 2 -n 400 > ${EXPORT_DIR}/us_paid_business.csv
ruby indexApps_iOS.rb -c us -t 1 -g 3 -n 400 > ${EXPORT_DIR}/us_paid_catalogs.csv
ruby indexApps_iOS.rb -c us -t 1 -g 4 -n 400 > ${EXPORT_DIR}/us_paid_education.csv
ruby indexApps_iOS.rb -c us -t 1 -g 5 -n 400 > ${EXPORT_DIR}/us_paid_entertainment.csv
ruby indexApps_iOS.rb -c us -t 1 -g 6 -n 400 > ${EXPORT_DIR}/us_paid_finance.csv
ruby indexApps_iOS.rb -c us -t 1 -g 7 -n 400 > ${EXPORT_DIR}/us_paid_games.csv
ruby indexApps_iOS.rb -c us -t 1 -g 8 -n 400 > ${EXPORT_DIR}/us_paid_health.csv
ruby indexApps_iOS.rb -c us -t 1 -g 9 -n 400 > ${EXPORT_DIR}/us_paid_lifestyle.csv
ruby indexApps_iOS.rb -c us -t 1 -g 10 -n 400 > ${EXPORT_DIR}/us_paid_medical.csv
ruby indexApps_iOS.rb -c us -t 1 -g 11 -n 400 > ${EXPORT_DIR}/us_paid_music.csv
ruby indexApps_iOS.rb -c us -t 1 -g 12 -n 400 > ${EXPORT_DIR}/us_paid_navigation.csv
ruby indexApps_iOS.rb -c us -t 1 -g 13 -n 400 > ${EXPORT_DIR}/us_paid_news.csv
ruby indexApps_iOS.rb -c us -t 1 -g 14 -n 400 > ${EXPORT_DIR}/us_paid_newsstand.csv
ruby indexApps_iOS.rb -c us -t 1 -g 15 -n 400 > ${EXPORT_DIR}/us_paid_photo.csv
ruby indexApps_iOS.rb -c us -t 1 -g 16 -n 400 > ${EXPORT_DIR}/us_paid_productivity.csv
ruby indexApps_iOS.rb -c us -t 1 -g 17 -n 400 > ${EXPORT_DIR}/us_paid_reference.csv
ruby indexApps_iOS.rb -c us -t 1 -g 18 -n 400 > ${EXPORT_DIR}/us_paid_social_networking.csv
ruby indexApps_iOS.rb -c us -t 1 -g 19 -n 400 > ${EXPORT_DIR}/us_paid_sports.csv
ruby indexApps_iOS.rb -c us -t 1 -g 20 -n 400 > ${EXPORT_DIR}/us_paid_travel.csv
ruby indexApps_iOS.rb -c us -t 1 -g 21 -n 400 > ${EXPORT_DIR}/us_paid_utilities.csv
ruby indexApps_iOS.rb -c us -t 1 -g 22 -n 400 > ${EXPORT_DIR}/us_paid_weather.csv

echo "\n---[ Fetching reviews... ]--------------------------\n"
ruby getReviews_iOS.rb ${EXPORT_DIR}/*.csv

echo "\n***************** Scrape complete. *****************\n"