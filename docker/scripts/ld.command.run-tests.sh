#!/usr/bin/env bash
# File
#
# This file contains run-tests -command for local-docker script ld.sh.

function ld_command_run-tests_exec() {
    CONT_ID=$(find_container ${CONTAINER_PHP:-php})
    if [ -z "$CONT_ID" ]; then
        echo -e "${Red}ERROR: PHP container ('${CONTAINER_PHP:-php}')is not up.${Color_Off}"
        exit 1
    fi
    TESTS=${@}
    SUB_COMM="/bin/su -s /bin/bash www-data -c 'test -f  web/core/scripts/run-tests.sh && php web/core/scripts/run-tests.sh --verbose --non-html --url http://${CONTAINER_NGINX:-nginx} --color ${TESTS} '"
    echo -e "${Cyan}Next: docker-compose exec ${CONTAINER_PHP:-php} bash -c \"${SUB_COMM}\"${Color_Off}"
    docker-compose exec ${CONTAINER_PHP:-php} bash -c "${SUB_COMM}"
}

function ld_command_run-tests_help() {
    echo "Run Drupal tests. NOTE that file paths are relative to ${APP_ROOT} -folder (web/...). ´--verbose´, ´--color´ and ´--non-html´ and ´--url´ -flags are added automatically. Classes need to be single quoted and double -backslashed."
}
