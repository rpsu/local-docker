#!/usr/bin/env bash

LOCAL_DOCKER_VERSION=1.x
LD_VERBOSE=${LD_VERBOSE:-2}

CWD=$(pwd)

PROJECT_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
if [[ ! -d "$PROJECT_ROOT" ]]; then PROJECT_ROOT="$PWD"; fi

cd $PROJECT_ROOT

# Get colors.
. ./docker/scripts/ld.colors.sh

# Get functions.
. ./docker/scripts/ld.functions.sh

required_binaries_check
case "$?" in
  1|"1") cd $CWD && echo -e "${Red}Docker is not running. Docker is required to use local-docker.${Color_Off}" && exit 1 ;;
  2|"2") cd $CWD && echo -e "${Red}Docker Compose was not found. It is required to use local-docker.${Color_Off}" && exit 1 ;;
  3|"3") cd $CWD && echo -e "${Red}Git was not found. It is required to use local-docker.${Color_Off}" && exit 1 ;;
esac

# 1st param, The Command.
ACTION=${1-'help'}

# Find all available commands.
for FILE in $(ls ./docker/scripts/ld.command.*.sh ); do
    FILE=$(basename $FILE)
    COMMAND=$(cut -d'.' -f3 <<<"$FILE")
    COMMANDS="$COMMANDS $COMMAND"
done

# Use fixed name, since docker-sync is supposed to be locally only.
DOCKERSYNC_FILE=docker-sync.yml
DOCKER_COMPOSE_FILE=docker-compose.yml
DOCKER_YML_STORAGE=./docker
DOCKER_PROJECT=$(basename $PROJECT_ROOT)



# Read (and create if necessary) the .env.local file, allowing overrides to any of our config values.
if [[ "$ACTION" != 'help' ]]; then
    import_config
    if [[ "$?" -ne "0" ]]; then
        create_project_config_file
        create_project_config_override_file
        import_config
        if [ "$?" -ne "0" ]; then
            echo -e "${Red}ERROR: Configuration files are not present nor could not be created. Exiting.${Color_Off}."
            exit 1
        fi
    fi
fi

# Get current script name, and use a symlink if it exists.
if [ ! -L "$( basename "$0" .sh)" ]; then
    SCRIPT_NAME=$PROJECT_ROOT/$( basename "$0")
    SCRIPT_NAME_SHORT=./$( basename "$0")
else
    SCRIPT_NAME=$PROJECT_ROOT/$( basename "$0" .sh)
    SCRIPT_NAME_SHORT=./$( basename "$0" .sh)
fi

if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    if [[ "$ACTION" != 'init' ]] && [[ "$ACTION" != 'help' ]] && [[ "$ACTION" != 'self-update' ]]; then
        [ "$LD_VERBOSE" -ge "1" ] && echo -e "${BYellow}Local-docker not yet initialized. Starting init now, please wait...${Color_Off}"
        $SCRIPT_NAME init
    fi
fi

case "$ACTION" in

"help")

    echo "Local-docker, version $LOCAL_DOCKER_VERSION"
    echo
    echo "This is a simple script, aimed to help in developer's daily use of local environment."
    echo "While local-docker is mainly targeted for Drupal, it works with any Composer managed codebase."
    echo "If you have docker-sync installed and configuration present (docker-sync.yml) it controls that too."
    echo
    echo 'Usage:'
    echo "$SCRIPT_NAME_SHORT [command]"
    echo
    echo "Available commands:"

    # Loop through all commands printing whatever they explain to be doing.
    for COMMAND in ${COMMANDS[@]}; do
      FILE=./docker/scripts/ld.command.$COMMAND.sh
      if [[ -f "$FILE" ]]; then
          . $FILE
          FUNCTION="ld_command_"$COMMAND"_help"
          function_exists $FUNCTION && echo -n "  - $COMMAND: $($FUNCTION)" && echo

      fi
    done
    cd $CWD
    exit 0
    ;;

*)
    # Loop through all commands printing whatever they explain to be doing.
    FILE=./docker/scripts/ld.command.$ACTION.sh

    if [[ -f "$FILE" ]]; then
        . $FILE
        FUNCTION="ld_command_"$ACTION"_exec"
        function_exists $FUNCTION && $FUNCTION ${@:2} || echo -e "${Red}ERROR: Command not found (hook '$FUNCTION' missing for command $ACTION).${Color_Off}."
    else
        echo -e "${Red}ERROR: Command not found (hook file missing).${Color_Off}."
    fi

esac

cd $CWD
