#!/usr/bin/env bash
TYPE=
declare -a SWIFT_VOLUMES=()
declare -a CINDER_VOLUMES=()

log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

main() {
    . /opt/getoptses/getoptses.sh

    local options
    options=$(getoptses -o "t:s:c:" --longoptions "type:,swift-volume:,cinder-volume:" -- "$@")

    if [[ "$?" -ne 0 ]]; then
        echo "Invalid option were specified" >&2
        return 1
    fi
    eval set -- "$options"

    while true; do
        case "$1" in
        --type | -t )
            [ -n "${TYPE}" ] && {
                log_err "A parameter \"type\" is declared"
            }
            TYPE="$1"
            shift 2
            ;;
        --swift-volume | -s )
            SWIFT_VOLUMES+=("$1")
            shift 2
            ;;
        --cinder-volume | -c )
            CINDER_VOLUMES+=("$1")
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

    log_info "Creating volumes with parameters[type=${TYPE},swift_volumes=${SWIFT_VOLUMES},cinder_volumes=${CINDER_VOLUMES}]"

    if [[ "${HOSTNAME}" =~ ^.*storage[0-9]+$ ]]; then
        prepare_storages_for_storage_node
    elif [[ "${HOSTNAME}" =~ ^.*swift[0-9]+$ ]]; then
        true
    elif [[ "${HOSTNAME}" =~ ^.*cinder[0-9]+$ ]]; then
        true
    else
        log_err "Unsupported operations to create vlumes for OpenStack storage nodes on a host \"${HOSTNAME}\". Hostname must contains a characters \"storage\", \"swift\" or \"cinder\"."
        return 1
    fi
}

prepare_storages_for_storage_node() {
    log_info "Preparing storages for swift and cinder because this host \"${HOSTNAME}\" is for all storages."
    prepare_storages_for_swift
    prepare_storages_for_cinder
}

prepare_storages_for_swift() {
    true
}

prepare_storages_for_cinder() {
    true
}



main "$@"
