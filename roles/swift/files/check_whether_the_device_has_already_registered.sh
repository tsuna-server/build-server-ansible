#!/usr/bin/env bash
log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

UUID_OF_DEVICE=

main() {
    local name_of_device="$1"
    local ret

    init_parameters "${name_of_device}"
    check_whether_the_device_has_already_registered && return 0
    register_device_into_fstab "${name_of_device}"

    return 0
}

init_parameters() {
    local name_of_device="$1"
    UUID_OF_DEVICE=$(grep -P "^${name_of_device}:.*" <<< "$(blkid)" | sed -e 's/.* UUID="\([a-z0-9\-]\+\).*" .*/\1/g')
    if [ -n "${UUID_OF_DEVICE}" ]; then
        # A device has already registered. Then return 1.
        log_info "The device \"${name_of_device}\" has already registered on the host $(hostname)."
        return 1
    fi
}

check_whether_the_device_has_already_registered() {
    local name_of_device="$1"

    grep -q -P "^${name_of_device}: .*" /etc/fstab && {
        log_info "A device \"${name_of_device}\" has already regsitered in \"/etc/fstab\". The instruction adding it into \"/etc/fstab\" will be skipped."
        return 0
    }

    return 1
}

register_device_into_fstab() {
    local name_of_device="$1"

    
}

main "$@"
