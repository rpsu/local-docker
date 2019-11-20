#!/usr/bin/env bash
# File
#
# This file contains dump -command for local-docker script ld.sh.

# Create a backup of one database.
function ld_command_db-backup_exec() {
    DBNAME=${1:-${MYSQL_DATABASE}}
    if [ -z "$DBNAME" ]; then
      echo -e "${Red}ERROR: No database name provided nor found.${Color_Off}"
      return 1
    fi

    DATE=$(date +%Y-%m-%d--%H-%I-%S)
    FILENAME="db-backup--${DBNAME}--$DATE.sql.gz"
    COMMAND_SQL_DB_DUMPER="mysqldump --host "${CONTAINER_DB:-db}" -uroot -p"$MYSQL_ROOT_PASSWORD" --lock-all-tables --compress --flush-logs --flush-privileges  --dump-date --tz-utc --verbose ${DBNAME} 2>/dev/null | gzip --fast -f > /var/db_dumps/${FILENAME}"

    db_connect
    RET="$?"
    case "$RET" in
        1|"1")
          echo -e "${Red}ERROR: Trying to locate a container with empty name.${Color_Off}"
          return $RET
          ;;

        2|"2")
          if ! is_dockersync && [ -f "${DOCKER_PROJECT}/${DOCKERSYNC_FILE}" ]; then
            [ "$LD_VERBOSE" -ge "1" ] && echo 'Starting docker-sync, please wait...'
            docker-sync start
            DOCKER_SYNC_STARTED=1
          fi
          COMM="docker-compose -f $DOCKER_COMPOSE_FILE  up -d $CONTAINER_DB"
          [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Yellow}Starting DB container for backup purposes.${Color_Off}"
          $COMM
          STARTED=1
          ;;

        3|"3")
         echo -e "${Red}ERROR: DB container not running (or not yet created).${Color_Off}"
         return $RET
       ;;
    esac

    [ "$LD_VERBOSE" -ge "1" ] && echo -e "${Yellow}Using datestamp: $DATE${Color_Off}"
    [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}NEXT: docker-compose -f $DOCKER_COMPOSE_FILE exec ${CONTAINER_DB:-db} sh -c $COMMAND_SQL_DB_DUMPER${Color_Off}"

    docker-compose -f $DOCKER_COMPOSE_FILE exec ${CONTAINER_DB:-db} sh -c "$COMMAND_SQL_DB_DUMPER"
    cd $PROJECT_ROOT/$DATABASE_DUMP_STORAGE
    ln -sf ${FILENAME} db-backup--${DBNAME}--LATEST.sql.gz

    if [ ! -z "$STARTED" ]; then
       [ "$LD_VERBOSE" -ge "1" ] && echo -e "${Yellow}Stopping DB container.${Color_Off}"
       COMM="docker-compose -f $DOCKER_COMPOSE_FILE stop $CONTAINER_DB"
        [ "$LD_VERBOSE" -ge "2" ] && echo -e "${Cyan}Next: $COMM${Color_Off}"
       $COMM
    fi
    if [ ! -z "$DOCKER_SYNC_STARTED" ]; then
        [ "$LD_VERBOSE" -ge "1" ] && echo 'Turning off docker-sync (stop), please wait...'
        docker-sync stop
    fi
    echo "DB backup of database ${DBNAME} in $DATABASE_DUMP_STORAGE/${FILENAME}"
    echo "DB backup of ${DBNAME} symlinked from: $DATABASE_DUMP_STORAGE/db-backup--${DBNAME}--LATEST.sql.gz"

}

function ld_command_db-backup_help() {
    echo "Backup a single database. Optionally provide database name (default: ${MYSQL_DATABASE}). Dump file will be place in $DATABASE_DUMP_STORAGE -folder."
}