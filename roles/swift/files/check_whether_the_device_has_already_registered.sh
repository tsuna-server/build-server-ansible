#!/usr/bin/env bash
log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

main() {
    local name_of_device="$1"

    check_whether_the_device_has_already_registered "${name_of_device}" || return 1
    register_device_into_fstab "${name_of_device}"

    return 0
}

check_whether_the_device_has_already_registered() {
    local name_of_device="$1"

    grep -q -P "^${name_of_device}: .*" /etc/fstab && {
        log_info "A device \"${name_of_device}\" has already regsitered in \"/etc/fstab\". The instruction adding it into \"/etc/fstab\" will be skipped."
        return 0
    }

    return 0
}

register_device_into_fstab() {
    local name_of_device="$1"

}

main "$@"
