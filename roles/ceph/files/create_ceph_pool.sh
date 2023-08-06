#!/usr/bin/env bash
log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

main() {
    local pool_name="$1"
    local num_of_placement_groups="$2"
    local result

    if [ "${#@}" -ne 2 ]; then
        log_err "This script requires 2 argument, pool_name and num_of_placment_groups. But you specified ${#@} arguments (arguments=${@})"
        return 1
    fi
    if [[ ! "$num_of_placement_groups" =~ ^[0-9]+$ ]]; then
        log_err "A 2nd parameter must be a numeric. But you specified it as \"$num_of_placement_groups\""
        return 1
    fi

    result="$(ceph osd pool stats --format json | jq ".[] | select(.pool_name == \"${pool_name}\")")"

    if [ -n "$result" ]; then
        # The pool has already existed
        log_info "A pool \"$pool_name\" has already existed on this Ceph cluster. An instruction to create a pool of Ceph will be skipped."
        return 0
    fi

    # Creating a pool
    create_pool "$pool_name" "$num_of_placement_groups" || {
        log_err "Failed to create a pool pool_name=${pool_name},num_of_placement_groups=${num_of_placement_groups}"
        return 1
    }

    return 0
}

create_pool() {
    local pool_name="$1"
    local num_of_placement_groups="$2"

    ceph osd pool create "$pool_name" "$num_of_placement_groups" || {
        log_err "Failet to run a command \"ceph osd pool create \"$pool_name\" \"$num_of_placement_groups\"\""
        return 1
    }

    return 0
}

main "$@"
