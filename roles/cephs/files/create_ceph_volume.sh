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

    return 0
}

format_device() {
    local device="$1"

    parted --script ${device} 'mklabel gpt' || {
        log_err "Failed to make a label as gpt with a command \"parted --script ${device} 'mklabel gpt'\"."
        return 1
    }
    parted --script ${device} "mkpart primary 0% 100%" || {
        log_err "Failed to make partition with a command \"parted --script ${device} 'mkpart primary 0% 100%'\"."
        return 1
    }

    log_info "Creating a ceph volume at ${device}1 on ${HOSTNAME}"

    ceph-volume lvm create --data ${device}1 || {
        log_err "Failed to create LVM on a device \"${device}1\""
        return 1
    }
}

main "$@"
