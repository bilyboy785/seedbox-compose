#!/bin/bash

# PARAMETERS
SEEDUSER="/%USER%/"
USERDIR="/home/%USER%/dockers/"
BACKUPDIR="%BACKUPDIR%"
RETENTIONDAILY="%DAILYRET%"
RETENTIONWEEKLY="%WEEKLYRET%"
RETENTIONMONTHLY="%MONTHLYRET%"
DATE=`date +"%d-%m-%Y"`
#date_weekly=`date +"%V sav. %m-%Y"`
#date_monthly=`date +"%m-%Y"`

# GET CURRENT MONTH & WEEK DAYS
MONTHDAY=`date +"%d"`
WEEKDAY=`date +"%u"`

# DESTINATION FILENAME
FILENAME="sc-%USER%-$DATE.tar.gz"

# CHECK THE DATE
if [[ "$MONTHDAY" == "1" ]]; then
    DESTINATION="monthly-backup"
    # monthly - Default keep for 300 days
	find $BACKUPDIR$DESTINATION$SEEDUSER -maxdepth 1 -mtime +%MONTHLYRET% -type d -exec rm -rv {} \;
else
  # On sunday do
  if [[ "$WEEKDAY" == "7" ]]; then
    DESTINATION="weekly-backup"
    # WEEKLY - Default keep for 60 days
	find $BACKUPDIR$DESTINATION$SEEDUSER -maxdepth 1 -mtime +%WEEKLYRET% -type d -exec rm -rv {} \;
  # others days
  else
    DESTINATION="daily-backup"
    # DAILY - Default keep for 14 days
	  find $BACKUPDIR$DESTINATION$SEEDUSER -maxdepth 1 -mtime +%DAILYRET% -type d -exec rm -rv {} \;
  fi
fi

# CREATING FOLDER
mkdir -p $BACKUPDIR$DESTINATION$SEEDUSER

# BACKING UP IF DOESN'T EXIST
BACKUP="$BACKUPDIR$DESTINATION$SEEDUSER$FILENAME"
if [[ ! -f "$BACKUP"]]; then
	tar cvpzf $BACKUP $USERDIR > /dev/null 2>&1
fi