#!/bin/bash

# pantheon-backup-to-s3.sh
# Script to backup Pantheon sites and copy to Amazon s3 bucket
#
# Requirements:
#   - Pantheon terminus cli
#   - Valid terminus machine token
#   - Amazon aws cli
#   - s3 cli access and user configured

while getopts u:s:e:d: flag
do
    case "${flag}" in
        u) TERMINUSUSER=${OPTARG};; # The Pantheon terminus user (email address)
        s) SITENAMES=${OPTARG};; # Site names to backup (e.g. 'site-one site-two')
        e) SITEENVS=${OPTARG};; # Site environments to backup (any combination of dev, test and live)
        d) BACKUPDIR=${OPTARG};; # Local backup directory (must exist, requires trailing slash)
    esac
done

# Elements of backup to be downloaded.
ELEMENTS="code db files"
# Helper variable
SLASH="/"
# Prepend to help when it comes to deleting
PANTHEONDIRNAME=pantheon-backup-
# Date
BACKUPDATE=$(date +%Y%m%d)
# Date in milliseconds
BACKUPDATEINMILLISECONDS=$(date +%Y%m%d%s)
# Set to true if you want pantheon to create a new backup. Otherwise it uses the most recent one created from the schedule.
CREATEBACKUP=false
# This sets the proper file extension
EXTENSION="tar.gz"
DBEXTENSION="sql.gz"
# Hide Terminus update messages
TERMINUS_HIDE_UPDATE_MESSAGES=0

# connect to terminus
terminus auth:login --email $TERMINUSUSER

if [ ! -d $BACKUPDIR$SLASH$PANTHEONDIRNAME$BACKUPDATE ]; then
  mkdir -p $BACKUPDIR$SLASH$PANTHEONDIRNAME$BACKUPDATE;
fi

# iterate through sites to backup
for thissite in $SITENAMES; do
  # iterate through current site environments
  for thisenv in $SITEENVS; do
    # create backup
    if [[ $CREATEBACKUP == true ]]; then
      terminus backup:create $thissite.$thisenv
    fi

    # iterate through backup elements
    for element in $ELEMENTS; do
      # download current site backups
      if [[ $element == "db" ]]; then
        terminus backup:get --element=$element --to=$BACKUPDIR$SLASH$PANTHEONDIRNAME$BACKUPDATE$SLASH$thissite.$thisenv.$element.$BACKUPDATEINMILLISECONDS.$DBEXTENSION $thissite.$thisenv
      else
        terminus backup:get --element=$element --to=$BACKUPDIR$SLASH$PANTHEONDIRNAME$BACKUPDATE$SLASH$thissite.$thisenv.$element.$BACKUPDATEINMILLISECONDS.$EXTENSION $thissite.$thisenv
      fi
    done
  done
done
echo $BACKUPDIR