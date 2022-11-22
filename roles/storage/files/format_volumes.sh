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
        prepare_storages_for_swift
    elif [[ "${HOSTNAME}" =~ ^.*cinder[0-9]+$ ]]; then
        prepare_storages_for_cinder
    else
        log_err "Unsupported operations to create vlumes for OpenStack storage nodes on a host \"${HOSTNAME}\". Hostname must contains a characters \"storage\", \"swift\" or \"cinder\"."
        return 1
    fi
}

prepare_storages_for_storage_node() {
    log_info "Preparing storages for swift and cinder because this host \"${HOSTNAME}\" is for all storages."
    prepare_storages_for_cinder
    prepare_storages_for_swift
}

prepare_storages_for_swift() {
    for device in "${SWIFT_VOLUMES}"; do
        create_storage_for_swift "${device}"
    done
    return 0
}

prepare_storages_for_cinder() {
    for device in "${SWIFT_VOLUMES}"; do
        create_storage_for_cinder "${device}"
    done
    return 0
}

create_storage_for_swift() {
    local deivce="$1"
    local output ret

    output="$(blkid "$device")"

    grep -q -F 'TYPE="xfs"' <<< "$output"
    ret=$?

    if [ -z "${output}" ]; then
        # The device is not formatted yet. Then the device can be formatted.
        log_info "The device \"${device}\" is not formatted yet. It will be formatted as XFS file system."
        format_as_xfs "${device}"
    else [ ${ret} -eq 0 ]; then
        log_info "The device \"${device}\" is already formatted. Then an instruction to create XFS file system for Swift will be skipped."
        return 0
    else
        log_err "The device \"${device}\" is already formatted but a format of it is unexpected. A information of the device like below."
        log_err "${output}"
        return 1
    fi
}

create_storage_for_cinder() {
    local deivce="$1"
    local output_of_pvdisplay ret_of_pvdisplay output_of_vg_name ret_of_vg_name

    [ -b "${device}" ] || {
        log_err "A device \"${device}\" is not present."
        return 1
    }

    output_of_pvdisplay="$(pvdisplay "${device}")"
    ret_of_pvdisplay=$?



    if [ ${ret_of_pvdisplay} -eq 0 ]; then
        # A device has already been formatted as LVM.

        output_of_vg_name=$(grep -q -P '^.*VG Name .*cinder\-volumes$' <<< "${output_of_pvdisplay}")
        ret_of_vg_name=$?
        if [ ${ret_of_vg_name} -ne 0 ]; then
            log_err "A device \"${device}\" has already been formatted as LVM but VG Name is different from \"cinder-volumes\". An output of volume name is \"${output_of_vg_name}\""
            return 1
        fi

        log_info "A device \"${device}\" has already been formatted as LVM."
        return 0
    fi
    # | Not partitioned |                 |                 |
    # | or              |                 |                 |
    # | Partitioned     | Formatted       | Proceed         |
    # | labeled LVM     | with any FS     | creating LVM?   |
    # +-----------------+-----------------+-----------------|
    # | False           | False           | True            |
    # | True            | False           | True            |
    # | False           | True            | False           |
    # | True            | True            | False           |
    #
    # TODO: 
}

format_as_xfs() {
    local device="$1"
    local ret
    mkfs.xfs "${device}"
    ret=$?

    if [ $ret -ne 0 ]; then
        log_err "Failed to foramt a device \"${device}\" as XFS. The actual error messages might be outputted before this message."
        return 1
    fi
}

main "$@"
