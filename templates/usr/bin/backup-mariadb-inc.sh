#!/bin/bash
BACKUP_DIR="{{ moodlebox_db_mount }}/backup/mariadb"
BACKUP_ERROR_LOGS="/var/log/mariadb_error.log"
BACKUP_INFO_LOGS="/var/log/mariadb_info.log"

mkdir -pv ${BACKUP_DIR}
find ${BACKUP_DIR}/* -type d -mmin +$((60*72)) -exec rm -rf {} \; # delete backup directories older than 72 hours

DAY_DIR=${BACKUP_DIR}/$(date +%Y-%m)
TARGET_DIR=${DAY_DIR}/$(date +%d_%Hh_full)

if [[ -e $TARGET_DIR ]]; then
    printf "[`date --iso-8601=ns`] Directory ${TARGET_DIR} already exists\n" >> ${BACKUP_ERROR_LOGS}
else
    mkdir -pv ${DAY_DIR}

    if [[ -e ${DAY_DIR}/last_completed_backup ]]; then
        BASE_DIR=$(head -n 1 ${DAY_DIR}/last_completed_backup)
        
        if [[ -z ${BASE_DIR} ]]; then
            printf "[`date --iso-8601=ns --utc`] Base dir is an empty string\n" >> ${DAY_DIR}my_error.log
        else
            mkdir -pv ${TARGET_DIR}

            SECONDS=0

            mariabackup --backup \
                --target-dir=${TARGET_DIR} \
                --incremental-basedir=${BASE_DIR} \
                --user="{{ moodlebox_db_username }}" \
                --password="{{ moodlebox_db_password }}" >> ${BACKUP_INFO_LOGS} 2>> ${BACKUP_ERROR_LOGS}

            printf "completed in ${SECONDS} seconds\n" >> ${BACKUP_INFO_LOGS}

            printf "${TARGET_DIR}" > ${DAY_DIR}/last_completed_backup
        fi
    else
        printf "[`date --iso-8601=ns --utc`] No base dir for incremental backup\n" >> ${BACKUP_ERROR_LOGS}
    fi
fi