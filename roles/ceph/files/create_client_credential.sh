#!/usr/bin/env bash
log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

main() {
    local name_of_credential="$1"
    local permission_of_mon="$2"
    local permission_of_osd="$3"

    if [ ${#@} -ne 3 ]; then
        log_err "This script requires only 3 arguments. But you specified ${#@} arguments."
        return 1
    fi

    create_client_credential "$name_of_credential" "$permission_of_mon" "$permission_of_osd" || {
        log_err "Failed to create a client credential"
        return 1
    }

    return 0
}

create_client_credential() {
    local name_of_credential="$1"
    local permission_of_mon="$2"
    local permission_of_osd="$3"
    local result

    result=$(ceph auth ls --format json | jq ".auth_dump[] | select(.entity == \"${name_of_credential}\")")

    if [ -n "$result" ]; then
        log_info "A credential \"${name_of_credential}\" has already existed. Then creating a credential of client will be skipped."
        return 0
    fi

    ceph auth get-or-create "$name_of_credential" mon "$permission_of_mon" osd "$permission_of_osd" || {
        log_err "Failed to get-or-create a credential of client. ceph auth get-or-create \"${name_of_credential}\" mon \"${permission_of_mon}\" \"${permission_of_osd}\""
        return 1
    }

    return 0
}

main "$@"
