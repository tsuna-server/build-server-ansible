#!/usr/bin/env bash
log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

main() {
    local pool_name="$1"

    if [ -z "$pool_name" ]; then
        log_err "This script requires 1 argument as name of Ceph pool. You did not specified it."
        return 1
    fi

    return 0
}

main "$@"
