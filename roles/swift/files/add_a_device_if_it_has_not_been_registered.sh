#!/usr/bin/env bash
log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

DESTINATION_OF_DIRECTORY_TO_MOUNT="/srv/node"
UUID_OF_DEVICE=

main() {
    local name_of_device="$1"
    local base_name_of_device=$(basename "${name_of_device}")
    local ret=

    if [ -z "${base_name_of_device}" ]; then
        log_err "Failed to get a basename of the device[name_of_device=${name_of_device},base_name_of_device=(empty)]"
        return 1
    fi

    init_parameters "${name_of_device}" || return 1
    #check_whether_the_device_has_already_registered "${name_of_device}"
    check_whether_the_device_has_already_registered "${base_name_of_device}"
    ret=$?

    if [ $ret -eq 0 ]; then
        # This program returns 0 if the device has already registered.
        # An instruction to mount the device will be skipped.
        return 0
    fi

    register_device_into_fstab "${name_of_device}" "${base_name_of_device}" || return 1

    return 0
}

init_parameters() {
    local name_of_device="$1"
    UUID_OF_DEVICE=$(blkid "${name_of_device}" | sed -e 's/.* UUID="\([a-z0-9\-]\+\).*" .*/\1/g')
    if [ -z "${UUID_OF_DEVICE}" ]; then
        # A device has already registered. Then return 1.
        log_err "The device \"${name_of_device}\" has NOT been formatted. A device of UUID could not be obtained with the command \"blkid\"."
        return 1
    fi

    return 0
}

# Check whether the device has already registered.
# A meaning of a value that will be returned are like below.
#   0: A device has already regsiteed.
#   1: A device has NOT registered.
check_whether_the_device_has_already_registered() {
    local base_name_of_device="$1"

    grep -q -P "^UUID=\"${UUID_OF_DEVICE}\" +${DESTINATION_OF_DIRECTORY_TO_MOUNT}/${base_name_of_device} .*" /etc/fstab && {
        log_info "A device \"${name_of_device}\" has already regsitered as UUID=${UUID_OF_DEVICE} in \"/etc/fstab\". The instruction adding it into \"/etc/fstab\" will be skipped."
        return 0
    }

    return 1
}

register_device_into_fstab() {
    local name_of_device="$1"
    local base_name_of_device="$2"

    [ -z "${UUID_OF_DEVICE}" ] && {
        log_err "A function register_device_into_fstab() requires a variable UUID_OF_DEVICE has already set. A value of UUID_OF_DEVICE is empty."
        return 1
    }

    # This instruction assumes that the device has NOT registered.
    echo "UUID=\"${UUID_OF_DEVICE}\" ${DESTINATION_OF_DIRECTORY_TO_MOUNT}/${base_name_of_device} xfs noatime 0 2" >> /etc/fstab || {
        log_err "Failed to register a device \"${base_name_of_device}\" with uuid \"${UUID_OF_DEVICE}\" into /etc/fstab on node ${HOSTNAME}"
        return 1
    }

    return 0
}

mount_device() {
    local base_name_of_device="$1"

    mount "${DESTINATION_OF_DIRECTORY_TO_MOUNT}/${base_name_of_device}" || {
        log_err "Failed to mount a directory ${DESTINATION_OF_DIRECTORY_TO_MOUNT}/${base_name_of_device}."
        return 1
    }

    return 0
}

main "$@"
