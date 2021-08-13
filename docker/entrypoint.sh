#!/usr/bin/env bash

PYTHON_VIRTUALENV_DIRECTORY="venv"
ANSIBLE_DIRECTORY="/opt/ansible"
PHYSICAL_VENV_DIRECTORY="/opt/venv"

log_err() {
    echo "ERROR: $1" >&2
}

main() {
    local inventry_file="$1"
    local target="$2"

    [[ -z "$inventry_file" ]] && {
        log_err "This program requires inventry file."
        return 1
    }
    [[ -z "$target" ]] && {
        log_err "This program requires target host."
        return 1
    }

    cd "$ANSIBLE_DIRECTORY" || {
        log_err "Failed to change directory to $ANSIBLE_DIRECTORY"
        return 1
    }

    create_ansible_environment || {
        log_err "Failed to create Ansible environment"
        return 1
    }

    prepare_ssh_key || {
        log_err "Failed to prepare ssh-keys to authenticate"
        return 1
    }

    echo "inventry_file = ${inventry_file}, target = ${target}"
    echo "$@"

    ${ANSIBLE_DIRECTORY}/${PYTHON_VIRTUALENV_DIRECTORY}/bin/ansible-playbook -i "$inventry_file" -l "$target" site.yml
}

create_ansible_environment() {

    local prepared_flag_file="${ANSIBLE_DIRECTORY}/${PYTHON_VIRTUALENV_DIRECTORY}/.ansible_environment_has_already_prepared"
    [[ -f "$prepared_flag_file" ]] && return

    python3 -m "$PYTHON_VIRTUALENV_DIRECTORY" "${PYTHON_VIRTUALENV_DIRECTORY}/" || {
        log_err "Failed to install python virtual env in $ANSIBLE_DIRECTORY"
        return 1
    }

    # Create symbolic link to cache packages of ansible-galaxy
    ln -s "${ANSIBLE_DIRECTORY}/.ansible" ~/.ansible

    ${ANSIBLE_DIRECTORY}/${PYTHON_VIRTUALENV_DIRECTORY}/bin/pip install --upgrade pip
    #python3 -m pip install --upgrade pip

    #${ANSIBLE_DIRECTORY}/${PYTHON_VIRTUALENV_DIRECTORY}/bin/pip --upgrade pip
    ${ANSIBLE_DIRECTORY}/${PYTHON_VIRTUALENV_DIRECTORY}/bin/pip install -r requirements.txt
    #python3 -m pip install -r requirements.txt

    #/opt/ansible/venv/bin/ansible-galaxy 
    ${ANSIBLE_DIRECTORY}/${PYTHON_VIRTUALENV_DIRECTORY}/bin/ansible-galaxy install -r requirements.yml

    touch "$prepared_flag_file"
}

prepare_ssh_key() {
    mkdir ~/.ssh

    [[ ! -f "/private-key" ]] && {
        log_err "private-key file does not existed"
        return 1
    }

    cp /private-key ~/.ssh/private-key || {
        log_err "Failed to copy /private-key to user's ssh config directory"
        return 1
    }

    cat << EOF > ~/.ssh/config
Host *
    ServerAliveInterval 120
    PreferredAuthentications publickey,password,gssapi-with-mic,hostbased,keyboard-interactive
    User root
    IdentityFile ~/.ssh/private-key
EOF

    chmod 700 ~/.ssh
    chmod -R 600 ~/.ssh/*
}

main "$@"
