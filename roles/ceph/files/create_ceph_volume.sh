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
        # If the name of device is end with numbers (eg. /dev/vda3), it is assumed that the device has NOT been partitioned.
        log_info "Create a partition on ${device}."
        parted --script ${device} 'mklabel gpt'
        parted --script ${device} "mkpart primary 0% 100%"
        # Create a ceph volume on the partition.
        device="${device}1"
    fi

    log_info "Creating a ceph volume at ${device} on ${HOSTNAME}"

    count=0

    while [ ${count} -lt 30 ]; do
        # If the name of device is end with numbers (eg. /dev/vda3), it is assumed that the device has NOT been partitioned.

        create_lvm_volume_for_ceph "${device}" && break

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

create_lvm_volume_for_ceph() {
    local device="$1"
    local output_pvdisplay pv_name vg_name new_vg_name ret

    # Create a LVM volume group
    output_pvdisplay="$(pvdisplay ${device} 2> /dev/null)"
    ret=$?
    if [ $ret -ne 0 ]; then
        pvcreate ${device}

        if [ $? -ne 0 ]; then
            log_err "Failed to create a LVM physical volume \"${device}\"."
            return 1
        fi
    fi

    # Get a volume group name from the output.
    # This instruction assumes that the physical volume has already been existed by do_create_phiysical_volume().
    vg_name=$(pvdisplay ${device} | grep "VG Name" | sed -e 's/.*VG Name \+\(.\+\)/\1/g')
    if [[ ! "${value}" =~ ^ceph\-[0-9a-z]{8}(\-[0-9a-z]{4}){3}\-[0-9a-z]{12}$ ]]; then
        log_err "Failed assert name of volume group. The name was succeeded in getting from the command \"pvdisplay ${device}\" but its format is not matched. Actual value was \"${vg_name}\"."
        return 1
    fi

    vgdisplay ${vg_name} > /dev/null 2>&1
    ret=$?
    if [ $ret -ne 0 ]; then
        new_vg_name="ceph-$(uuidgen)"
        vgcreate ${new_vg_name} ${device}

        if [ $? -ne 0 ]; then
            log_err "Failed to create a LVM volume group \"${new_vg_name}\" with device \"${device}\"."
            return 1
        fi
    fi

    lvdisplay ${vg_name} > /dev/null 2>&1
    ret=$?
    if [ $ret -ne 0 ]; then
        new_lv_name="osd-block-$(uuidgen)"
        lvcreate -l 100%FREE -n ${new_lv_name} ${vg_name}
        if [ $? -ne 0 ]; then
            log_err "Failed to create LVM logical volume \"${new_lv_name}\"."
        fi
    fi

    return 0
}

main "$@"
