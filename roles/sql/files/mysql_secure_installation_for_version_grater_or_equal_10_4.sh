#!/usr/bin/env bash

main() {
    local password="$1"

    # Automating mysql_secure_installation
    # https://gist.github.com/Mins/4602864

    DEBIAN_FRONTEND=noninteractive apt-get -y install expect || {
        echo "ERROR: Failed to install expect." >&2
        exit 1
    }

    expect -c "
set timeout 30

"

    DEBIAN_FRONTEND=noninteractive apt-get -y purge expect
}

main "$@"

