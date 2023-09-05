#!/usr/bin/env bash

log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

main() {
    local target_hosts="$@"
    local clause=""
    local delimiter=""
    local target

    if [ ${#target_hosts[@]} -eq 0 ]; then
        log_err "This script requires target hosts that will be added in a cell with \"cell_id == 1\""
        return 1
    fi

    for target in ${target_hosts}; do
        clause+="${delimiter}${target}"
        delimiter=","
    done

    #mysql -D nova_api <<< 'select id , cell_id, host from host_mappings;'
    mysql -N -D nova_api <<< "select host from host_mappings where host in (\"${clause}\");"
}

main "$@"
