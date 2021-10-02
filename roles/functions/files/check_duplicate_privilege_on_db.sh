#!/usr/bin/env bash

main() {
    local db="$1"
    local user="$2"
    local host="$3"

    if [[ -z "$db" ]] || [[ -z "$user" ]] || [[ -z "$host" ]]; then
        echo "Usage: $0 <db> <user> <host>"
        return 2
    fi

    grep -q -P "^GRANT ALL PRIVILEGES ON \`${db}\`\.\* TO \`${user}\`@\`${host}\`$" \
            <<< "$(mysql -e "SHOW GRANTS FOR '${user}'@'${host}'" ${db} | sed -e 's/\|//g' | sed -e 's/^ *\| *$//g')" && {
        echo "INFO: A privilege of user \"${user}\" on '${user}'@'${host}' was already set."
        return 1
    }

    echo "INFO: A privilege of user \"${user}\" on '${user}'@'${host}' was NOT set yet."
    return 0
}

main "$@"
