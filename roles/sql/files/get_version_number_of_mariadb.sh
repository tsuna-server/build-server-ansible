#!/usr/bin/env bash

main() {
    local line version_text version
    line=$(dpkg --list mariadb-server | grep -P '^ii .*') || {
        echo "ERROR: Failed to get a package information of mariadb-server" >&2
        exit 1
    }

    read _ _ version_text _ <<< "$line"
    version=$(sed -e 's/.*:\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/g' <<< "$version_text")

    [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && {
        echo "ERROR: A format of version is in correct. A version that this program got is \"${version}\"" >&2
        exit 1
    }

    echo "$version"
    return 0
}

main "$@"

