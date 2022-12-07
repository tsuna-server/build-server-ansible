#!/usr/bin/env bash

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

    return 0
}

main "$@"
