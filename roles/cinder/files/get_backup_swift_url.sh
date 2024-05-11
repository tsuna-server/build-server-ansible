#!/usr/bin/env bash

main() {
    local swift_url
    swift_url=$(jq -r ".endpoints[] | select(.interface == \"internal\") | .url" < <(openstack catalog show object-store -f json))

    #if [ -z "$swift_url" ]; then
    #    return 1
    #fi
    echo "$swift_url"
    return 0
}

main "$@"
