#!/usr/bin/env bash

BUILDER=
IP=
NAME_OF_DEVICE=

log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

main() {
    . /opt/getoptses/getoptses.sh

    local options
    options=$(getoptses -o "b:i:d" --longoptions "builder:,ip:,name-of-device" -- "$@")

    if [[ "$?" -ne 0 ]]; then
        echo "Invalid option were specified" >&2
        return 1
    fi
    eval set -- "$options"

    case "$1" in
        --builder | -b )
            BUILDER="$2"
            shift 2
            ;;
        --ip | -i )
            IP="$2"
            shift 2
            ;;
        --name-of-device | -d )
            NAME_OF_DEVICE="$2"
            shift 2
            ;;
        -- )
            shift
            break
            ;;
        * )
            log_err "Internal error has occured while parsing options. [raw_options=\"$@\"]"
            return 1
            ;;
    esac

    validate_options || return 1
    check_duplicate_element

    return 0
}

validate_options() {
    if [ -z "${BUILDER}" ]; then
        log_err "The option -b|--builder has not set. It is required."
        return 1
    fi
    if [ -z "${IP}" ]; then
        log_err "The option -i|--ip has not set. It is required."
        return 1
    fi
    if [ -z "${NAME_OF_DEVICE}" ]; then
        log_err "The option -d|--name-of-device has not set. It is required."
        return 1
    fi

    return 0
}

main "$@"
