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
                return 1
            }
            TYPE="$2"
            shift 2
            ;;
        --swift-volume | -s )
            SWIFT_VOLUMES+=("$2")
            shift 2
            ;;
        --cinder-volume | -c )
            CINDER_VOLUMES+=("$2")
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

    log_info "Creating volumes with parameters[type=${TYPE},swift_volumes=[${SWIFT_VOLUMES[@]}],cinder_volumes=[${CINDER_VOLUMES[@]}]]"

    verify_parameters || return 1

    #if [[ "${HOSTNAME}" =~ ^.*storage[0-9]+$ ]]; then
    if [ "${TYPE}" = "storage" ]; then
        prepare_storages_for_storage_node || return 1
    elif [ "${TYPE}" = "swift" ]; then
        prepare_storages_for_swift || return 1
    elif [ "${TYPE}" = "cinder" ]; then
        prepare_storages_for_cinder || return 1
    else
        log_err "Unsupported operations to create vlumes for OpenStack storage nodes on a host \"${HOSTNAME}\". Hostname must contains a characters \"storage\", \"swift\" or \"cinder\"."
        return 1
    fi

    log_info "Finished all instructions successfully."
    return 0
}

verify_parameters() {
    if [ -z "${TYPE}" ]; then
        log_err "This command requires \"--type <name>\" specified."
        return 1
    fi

    local ret_verify_cinder_volumes ret_verify_swift_volumes

    if [ "${TYPE}" = "storage" ]; then
        if [ ${#SWIFT_VOLUMES[@]} -eq 0 ] && [ ${#CINDER_VOLUMES[@]} -eq 0 ]; then
            log_err "A storage node must specify one or more volumes for Swift or Cinder. It does not specify any volumes(host_name=${HOSTNAME},\${#SWIFT_VOLUMES[@]}==0,\${#CINDER_VOLUMES[@]}==0)."
            return 1
        fi
        verify_swift_volumes || return 1
        verify_cinder_volumes || return 1
    elif [ "${TYPE}" = "swift" ]; then
        if [ ${#SWIFT_VOLUMES[@]} -lt 1 ]; then
            log_err "Wrong number of Swift volumes you specified. This script does not support lower than 1 Swift volume with the option \"--swift-volume <volume_name>\" on Swift node (hostname=${HOSTNAME})."
            return 1
        fi
    elif [ "${TYPE}" = "cinder" ]; then
        if [ ${#CINDER_VOLUMES[@]} -ne 1 ]; then
            log_err "Wrong number of Cinder volumes you specified. This script does not support other than 1 Cinder volume with the option \"--cinder-volume <volume_name>\" for simplicity (hostname=${HOSTNAME})."
            return 1
        fi
    fi
    return 0
}

prepare_storages_for_storage_node() {
    log_info "Preparing storages for swift and cinder because this host \"${HOSTNAME}\" is for all storages."
    prepare_storages_for_cinder || return 1
    prepare_storages_for_swift || return 1
    return 0
}

prepare_storages_for_swift() {
    [ ${#SWIFT_VOLUMES[@]} -eq 0 ] && {
        log_info "Ignore creating Swift volumes because num of them that you specified is 0."
        return 0
    }

    log_info "Preparing storages for swift. Target volumes "
    for device in "${SWIFT_VOLUMES[@]}"; do
        create_storage_for_swift "${device}"
    done
    return 0
}

prepare_storages_for_cinder() {
    [ ${#CINDER_VOLUMES[@]} -eq 0 ] && {
        log_info "Ignore creating Cinder volumes because num of them that you specified is 0."
        return 0
    }

    for device in "${CINDER_VOLUMES[@]}"; do
        create_storage_for_cinder "${device}" || return 1
    done
    return 0
}

create_storage_for_swift() {
    local deivce="$1"
    local output ret

    log_info "Creating XFS filesystem on a device \"${device}\" for Swift."

    output="$(blkid "$device")"

    if [ -z "${output}" ]; then
        # The device is not formatted yet. Then the device can be formatted.
        log_info "The device \"${device}\" is not formatted yet. It will be formatted as XFS file system for Swift."
        format_as_xfs "${device}" || return 1
        return 0
    fi

    grep -q -F 'TYPE="xfs"' <<< "$output"
    ret=$?

    if [ ${ret} -eq 0 ]; then
        log_info "The device \"${device}\" is already formatted. Then an instruction to create XFS file system for Swift will be skipped."
        return 0
    else
        log_err "The device \"${device}\" is already formatted but its format is unexpected. A information of the device like below."
        log_err "${output}"
        return 1
    fi
}

create_storage_for_cinder() {
    local deivce="$1"
    local output_of_pvdisplay ret_of_pvdisplay
    local output_of_vg_name ret_of_vg_name
    local output_of_blkid ret_of_blkid

    log_info "Creating LVM named \"cinder-volumes\" on a device \"${device}\" for Cinder."

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
            log_err "Failed to create LVM for Cinder. A device \"${device}\" has already been formatted as LVM but name of VG is different from \"cinder-volumes\". An output of volume name is \"${output_of_vg_name}\"."
            return 1
        fi

        log_info "Creating LVM has been skipped for Cinder. A device \"${device}\" has already been formatted as LVM for Cinder."
        return 0
    fi

    # |    | Partitioned     | Partitioned     | Formatted       | Proceed         |
    # | No | other than LVM  | labeled LVM     | with any FS(*1) | creating LVM?   |
    # +----+-----------------+-----------------+-----------------+-----------------|
    # | 1  | False           | False           | False           | True            |
    # | 2  | True            | False           | False           | False(Error)    |
    # | 3  | False           | True            | False           | False(Skipped)  |
    # | 4  | False           | False           | True            | False(Error)    |
    # | 5  | True            | True            | False           | False           | Unrealized
    # | 6  | True            | False           | True            | False(Error)    |
    # | 7  | False           | True            | True            | False(Error)    | Unrealized?
    # | 8  | True            | True            | True            | False           | Unrealized
    #
    # *1: Except LVM. LVM is not considered as FS in this scenario.

    output_of_blkid="$(grep -P "^${device}: " < <(blkid))"
    if [ -n "${output_of_blkid}" ]; then
        # A device has already been partitioned or formatted any file system.

        grep -q -i '^.* PARTLABEL="Linux LVM" .*$' <<< "${output_of_blkid}"
        ret_of_blkid=$?
        if [ ${ret_of_blkid} -ne 0 ]; then
            # No 2, No 4, No 6
            log_err "A device \"${device}\" has already been formatted and not labeld \"Linux LVM\" for Cinder."
            return 1
        fi

        TYPE="ext4" 
        output_of_blkid="$(grep -P '^.* TYPE="[a-zA-Z0-9_\- ]" .*$' <<< "${output_of_blkid}")"
        ret_of_blkid=$?
        if [ ${ret_of_blkid} -eq 0 ]; then
            # No 8
            log_err "A device \"${device}\" has been already formatted. Could not create LVM for Cinder. (${output_of_blkid})"
            return 1
        fi

        # no 3
        log_info "A device \"${device}\" has already been formatted by LVM and labeld \"Linux LVM\". Nothing to do. Skipped to create a LVM for cinder."
        return 0
    fi

    # No 1
    create_lvm_for_cinder "${device}" || return 1

    return 0
}

create_lvm_for_cinder() {
    local device="$1"

    wipefs --all "${device}" || {
        log_err "Failed to create LVM for cinder. A command to clean device \"${device}\" was failed. [wipefs --all \"${device}\"]"
        return 1
    }

    pvcreate "${device}" || {
        log_err "Failed to create LVM of physical volume at device \"${device}\". A command \"pvcreate ${device}\" was failed."
        return 1
    }


    vgcreate cinder-volumes "${device}" || {
        log_err "Failed to create LVM of volume group \"cinder-volumes\" at device \"${device}\". A command \"vgcreate cinder-volumes ${device}\" was failed."
        return 1
    }

    return 0
}

format_as_xfs() {
    local device="$1"
    local ret

    mkfs.xfs "${device}"
    ret=$?

    if [ $ret -ne 0 ]; then
        log_err "Failed to foramt a device \"${device}\" as XFS for Swift(ret=${ret}). The actual error messages might be outputted before this message."
        return 1
    fi
    return 0
}

main "$@"
