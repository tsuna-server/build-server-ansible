#!/usr/bin/env bash

log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

main() {
    local device="$1"

    if [ -z "$device" ]; then
        log_err "This script requires a name of device. But there are no arguments."
        return 1
    fi

    if [ ! -b "$device" ]; then
        log_err "A device you specified \"${device}\" might not be a drive. Failed a validation of \"test -b ${device}\"."
        return 1
    fi

    if [ -b "${device}1" ]; then
        log_info "A device \"${device}\" has already partitioned. A partitioned drive \"${device}1\" has already existed."
        return 0
    fi

    format_device "${device}" || return 1

    log_info "Succeeded in creating a ceph volume on ${device}."

    return 0
}

format_device() {
    local device="$1"
    local vg_name=

    if [[ ! "${device}" =~ [0-9]+$ ]]; then
        # If the name of device is end with numbers, it is assumed that the device has NOT been partitioned.
        log_info "Create a partition on ${device}."
        parted --script ${device} 'mklabel gpt'
        parted --script ${device} "mkpart primary 0% 100%"
        # Create a ceph volume on the partition.
        device="${device}1"
    fi

    log_info "Creating a ceph volume at ${device} on ${HOSTNAME}"

    count=0

    while [ ${count} -lt 30 ]; do
        ceph-volume lvm create --data ${device}
        vg_name=$(pvdisplay ${device} | grep -P "^ *VG Name *ceph\-.*\$" | grep -o '[^ ]*$')
        if [[ "${vg_name}" =~ ^ceph\-.*$ ]]; then
            log_info "Volume group for Ceph has found. vg_name=${vg_name}."
            break
        fi
        (( ++count ))

        log_info "Failed to create ceph volume(Obtained vg_name=${vg_name}). Retrying to execute it agin (count=${count})." >&2
        sleep 5
    done

    if [ $count -eq 30 ]; then
        log_err "Failed to create ceph volume after trying ${count} times."
        return 1
    fi

    return 0
}

main "$@"
