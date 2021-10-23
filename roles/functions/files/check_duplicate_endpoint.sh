#!/usr/bin/env bash
#
# This script validates whether the project is already existed in the domain or not.
# And this script assumes the domain was already existed.
#   return 1: The project was already existed
#   return 0: The project was NOT existed
#

main() {
    local target_region="$1"
    local target_service_name="$2"
    local target_service_type="$3"
    local target_service_interface="$4"

    local output region service_name service_type service_interface

    if [[ -z "$target_region" ]] || [[ -z "$target_service_name" ]] || [[ -z "$target_service_type" ]] || [[ -z "$target_service_interface" ]]; then
        echo "\$1: target_region, \$2: "
        return 2
    fi

    output="$(openstack endpoint list)" || {
        echo "ERROR: Failed to get endpoint list" >&2
        return 2
    }

    # Example output
    # +----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------+
    # | ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                                   |
    # +----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------+
    # | ...                              | ...       | ...          | ...          | ...     | ...       | ...                                   |
    # | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx | RegionOne | glance       | image        | True    | internal  | http://dev-private-router01:9292      |
    # | yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy | RegionOne | placement    | placement    | True    | public    | http://dev-private-router01:8778      |
    # | zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz  | RegionOne | nova         | compute      | True    | internal  | http://dev-private-router01:8774/v2.1 |
    # | ...                              | ...       | ...          | ...          | ...     | ...       | ...                                   |
    # +----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------------+

    while IFS="|" read -r region service_name service_type service_interface; do
        region="$(trim ${region})"
        service_name="$(trim "${service_name}")"
        service_type="$(trim "${service_type}")"
        service_interface="$(trim ${service_interface})"

        # "[DEBUG] region=${region}, service_name=${service_name}, service_type=${service_type}, service_interface=${service_interface}"

        if [[ "$region" == "$target_region" ]] \
                && [[ "$service_name" == "$target_service_name" ]] \
                && [[ "$service_type" == "$target_service_type" ]] \
                && [[ "$service_interface" == "$target_service_interface" ]]; then
            # The endpoint has already existed
            return 1
        fi
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 3,4,5,7)

    return 0
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

main "$@"

