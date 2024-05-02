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
        parted --script ${device} 'mklabel gpt' || {
            log_err "Failed to create a partition table on ${device}. [command: parted --script ${device} 'mklabel gpt']."
            return 1
        }
        parted --script ${device} "mkpart primary 0% 100%" || {
            log_err "Failed to create a partition on ${device}. [command: parted --script ${device} 'mkpart primary 0% 100%']."
            return 1
        }
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
    local output_pvdisplay output_lvdisplay pv_name vg_name lv_name ret

    # Create a LVM volume group
    output_pvdisplay="$(pvdisplay ${device} 2> /dev/null)" || {
        create_pv "${device}" || return 1
    }

    # Get a volume group name from the output.
    # This instruction assumes that the physical volume has already been existed by do_create_phiysical_volume().
    vg_name=$(pvdisplay ${device} | grep "VG Name" | sed -e 's/.*VG Name \+\(.\+\)/\1/g' | xargs echo -n)

    if [[ ! "${vg_name}" =~ ^\ *$ ]]; then
        if [[ ! "${vg_name}" =~ ^ceph\-[0-9a-z]{8}(\-[0-9a-z]{4}){3}\-[0-9a-z]{12}$ ]]; then
            log_err "Failed assert name of volume group. The name was succeeded in getting from the command \"pvdisplay ${device}\" but its format is not matched. Actual value was \"${vg_name}\"."
            return 1
        fi
        # Skip creating a volume group because it has already existed and its name is matched with the format.
    else
        # No volume group has existed.
        vg_name="ceph-$(uuidgen)"
        create_vg "${device}" "${vg_name}" || return 1
        vg_name=$(pvdisplay ${device} | grep "VG Name" | sed -e 's/.*VG Name \+\(.\+\)/\1/g')
    fi

    output_lvdisplay=$(lvdisplay ${vg_name} 2> /dev/null | grep -P "LV Name\s+osd-block-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
    if [[ -z "${output_lvdisplay}" ]]; then
        lv_name="osd-block-$(uuidgen)"
        create_lv "${device}" "${vg_name}" "${lv_name}" || return 1
    fi

    # TODO: Create a ceph volume and activate it.
    # https://forum.proxmox.com/threads/ceph-osd-creation-using-a-partition.58170/
    if [ -z "${lv_name}" ]; then
        activate_ceph_volume "${device}" "${lv_name}" || return 1
    fi

    return 0
}

create_pv() {
    local device="$1"

    pvcreate "${device}" || {
        log_err "Failed to create a LVM physical volume \"${device}\"."
        return 1
    }
    return 0
}

create_vg() {
    local device="$1"
    local new_vg_name="$2"

    vgcreate ${new_vg_name} ${device} || {
        log_err "Failed to create a LVM volume group \"${new_vg_name}\" with device \"${device}\"."
        return 1
    }
    return 0
}

create_lv() {
    local device="$1"
    local vg_name="$2"
    local lv_name="$3"

    lvcreate -l 100%FREE -n ${lv_name} ${vg_name} || {
        log_err "Failed to create a LVM logical volume \"${lv_name}\". [command:lvcreate -l 100%FREE -n \"${lv_name}\" \"${vg_name}\"]."
        return 1
    }
    return 0
}

activate_ceph_volume() {
    local lv_name="$1"
    local lv_path
    lv_name="${lv_name//-/\\-}"
    lv_path=$(lvdisplay | grep -P "LV Path .*/${lv_name}$" 2> /dev/null | awk '{print $3}')

    if [ -z "${lv_path}" ]; then
        log_err "Failed to get a path of logical volume \"${lv_name}\". [command: lvdisplay | grep -P \"LV Path .*/${lv_name}$\"]."
        return 1
    fi

    # TODO: Add error handling.
    ceph-volume lvm prepare --data "${lv_path}"
    ceph-volume lvm activate --all

    return 0
}

main "$@"
