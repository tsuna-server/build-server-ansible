#!/usr/bin/env bash
log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

main() {
    local expected_zone_name="$1"

    local max_attempts=30
    local count=0
    local zone_name=

    if [ -z "$expected_zone_name" ]; then
        log_err "This script requires 1 argument. There were no arguments."
        return 1
    fi

    while [ $count -lt $max_attempts ]; do
        zone_name="$(openstack availability zone list --volume --format json | jq -r '.[0]["Zone Name"]')"
        [ "$zone_name" = "${expected_zone_name}" ] && break
        (( ++count ))
        sleep 1
    done

    if [ $count -ge $max_attempts ]; then
        log_err "Failed to get Availability Zone \"${expected_zone_name}\" by a command \"openstack availability zone list --volume --format json | jq -r '.[0][\"Zone Name\"]'\". Actual obtained Availability Zone is \"${zone_name}\"."
        return 1
    fi

    log_info "Checking Availability Zone \"${expected_zone_name}\" has succeeded."

    return 0
}

main "$@"
