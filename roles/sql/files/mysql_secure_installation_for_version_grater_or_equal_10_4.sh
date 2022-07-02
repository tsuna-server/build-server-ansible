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
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"\r\"

expect \"Switch to unix_socket authentication [Y/n]\"
send \"\r\"

expect \"Change the root password? [Y/n]\"
send \"\r\"

expect \"New password:\"
send \"${password}\r\"

expect \"Re-enter new password:\"
send \"${password}\r\"

expect \"Remove anonymous users? [Y/n]\"
send \"\r\"

expect \"Disallow root login remotely? [Y/n]\"
send \"\r\"

expect \"Remove test database and access to it? [Y/n]\"
send \"\r\"

expect \"Reload privilege tables now? [Y/n]\"
send \"\r\"
"   || {
        echo "ERROR: Failed to execute mysql_secure_installation"
        exit 1
    }

    DEBIAN_FRONTEND=noninteractive apt-get -y purge expect
}

main "$@"

