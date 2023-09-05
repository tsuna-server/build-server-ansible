#!/usr/bin/env bash

log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

main() {
    local target_hosts="$@"

    mysql
    #mysql -D nova_api <<< 'select id , cell_id, host from host_mappings;'
    mysql -D nova_api <<< 'select host from host_mappings;'
}

main "$@"
