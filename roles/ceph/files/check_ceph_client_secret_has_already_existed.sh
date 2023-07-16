#!/usr/bin/env bash
log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

# Check virsh secret has already existed or not
#
# Returns...
#   0: If a ceph-client-secret has already existed.
#   1: If a ceph-client-secret has NOT existed.
#   2: Some errors were occurred
main() {
    local uuid_of_secret="$1"
    local ret

    if [ ${#@} -ne 1 ]; then
        log_err "This script requires 1 argument (name_of_secret). But you passed ${#@} arguments."
        return 2
    fi

    if [[ ! "$uuid_of_secret" =~ [0-9a-z]{8}\-[0-9a-z]{4}\-[0-9a-z]{4}\-[0-9a-z]{4}\-[0-9a-z]{12} ]]; then
        log_err "Failed to validate a parameter \"uuid_of_secret\" as UUID. Actual value is \"${uuid_of_secret}\"."
        return 2
    fi

    grep -Pq "^ ${uuid_of_secret} .*" < <(virsh --quiet secret-list)
    ret=$?

    if [ $ret -ne 1 ] && [ $ret -ne 0 ]; then
        log_err "Faield to get current virsh secret. A command \"virsh --quiet secret-list\" returned error. (Return code ${ret})"
        return 2
    fi

    return $ret
}

main "$@"
