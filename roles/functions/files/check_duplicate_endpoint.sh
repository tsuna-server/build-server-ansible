#!/usr/bin/env bash

main() {
    local target_region="$1"
    local target_service_name="$2"
    local target_service_type="$3"
    local target_service_interface="$4"

    local output region service_name service_type service_interface

    if [[ -z "$target_region" ]] || [[ -z "$target_service_type" ]] || [[ -z "$target_service_interface" ]]; then
        echo "\$1: target_region, \$2: "
        return 2
    fi

    output="$(openstack endpoint list)" || {
        echo "ERROR: Failed to get endpoint list" >&2
        return 2
    }

    # Example output of "openstack endpoint list"
    #+----------------------------------+-----------+--------------+--------------+---------+-----------+-----------------------------------------+
    #| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                                     |
    #+----------------------------------+-----------+--------------+--------------+---------+-----------+-----------------------------------------+
    #| 20c673870a574dfda6d40845e4533547 | RegionOne | glance       | image        | True    | internal  | http://dev-private-router01:9292        |
    #| 2b924c78af9f46ada9446cac957de861 | RegionOne | glance       | image        | True    | public    | http://dev-private-router01:9292        |
    #| 7e2bd9787dc64c698656d123d514aac9 | RegionOne | glance       | image        | True    | admin     | http://dev-private-router01:9292        |
    #+----------------------------------+-----------+--------------+--------------+---------+-----------+-----------------------------------------+

    #while read region service_name _; do
    while read region _ service_name _ service_type _ service_interface _; do
        region="${region%\\n}"
        service_name="${service_name%\\n}"
        service_type="${service_type%\\n}"
        service_interface="${service_interface%\\n}"
        echo "region=${region}, service_name=${service_name}, service_type=${service_type}, service_interface=${service_interface}"

        if [[ "$region" == "$target_region" ]] \
                && [[ "$service_name" == "$target_service_name" ]] \
                && [[ "$service_type" == "$target_service_type" ]] \
                && [[ "$service_interface" == "$target_service_interface" ]]; then
            return 1
        fi
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 3,4,5,7)

    return 0
}

main "$@"
