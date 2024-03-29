#!/usr/bin/env bash

WORK_DIR="/etc/swift"
BUILDER=
IP=
PORT=
DEVICE=

CODE_DUPLICATE_RING=99

log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

main() {
    local ret

    . /opt/getoptses/getoptses.sh

    echo "args=$@"

    cd "${WORK_DIR}" || {
        log_err "Failed to change a directory \"${WORK_DIR}\"."
        return 1
    }

    local options
    options=$(getoptses -o "b:i:d:p:" --longoptions "builder:,ip:,device:,port:" -- "$@")

    if [[ "$?" -ne 0 ]]; then
        echo "Invalid option were specified" >&2
        return 1
    fi
    eval set -- "$options"

    while true; do
        case "$1" in
            --builder | -b )
                BUILDER="$2"
                shift 2
                ;;
            --ip | -i )
                IP="$2"
                shift 2
                ;;
            --port | -p )
                PORT="$2"
                shift 2
                ;;
            --device | -d )
                DEVICE="$2"
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
    done

    log_info "builder=${BUILDER}, ip=${IP}, device=${DEVICE}"

    validate_options || return 1
    check_duplicate_element
    ret=$?
    if [ $ret -eq ${CODE_DUPLICATE_RING} ]; then
        return ${CODE_DUPLICATE_RING}
    elif [ $ret -ne 0 ]; then
        log_err "Failed to check_duplicate_element() for some reason[ret=${ret}]. Error messages might be outputted before this message."
        return 1
    fi

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
    if [ -z "${DEVICE}" ]; then
        log_err "The option -d|--name-of-device has not set. It is required."
        return 1
    fi

    return 0
}

check_duplicate_element() {
    local output
    local id region zone  ip_port replication_ip_port device_name weight partitions balance_flags_meta
    local ret_ip ret_device_name
    output="$(swift-ring-builder ${BUILDER} | grep -A999999 -m1 -P "^Devices: .*" | tail -n+2)"

    while read id region zone  ip_port replication_ip_port device_name weight partitions balance_flags_meta; do
        [[ "${ip_port}" =~ ^${IP}:${PORT}$ ]]
        ret_ip=$?
        [[ "${device_name}" =~ ^${DEVICE}$ ]]
        ret_device_name=$?

        [ ${ret_ip} -eq 0 -a ${ret_device_name} -eq 0 ] && return ${CODE_DUPLICATE_RING}
    done <<< "${output}"

    return 0
}

main "$@"
