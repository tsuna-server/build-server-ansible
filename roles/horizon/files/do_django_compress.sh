#!/usr/bin/env bash

SHA256_PATH_OPENSTACK_DASHBOARD_CONF="/root/.sha256_openstack_dashboard_conf"
SHA256_PATH_LOCAL_SETTINGS_PY="/root/.sha256_local_settings_py"

PATH_OPENSTACK_DASHBOARD_CONF="/etc/apache2/conf-available/openstack-dashboard.conf"
PATH_LOCAL_SETTINGS_PY="/etc/openstack-dashboard/local_settings.py"

SHA256_OPENSTACK_DASHBOARD_CONF=
SHA256_LOCAL_SETTINGS_PY=

main() {
    local ret_validate_openstack_dashboard_conf ret_validate_sha256_local_settings_py

    set_sha256_openstack_dashboard_conf || return 1
    set_sha256_local_settings_py        || return 1

    validate_sha256_openstack_dashboard_conf
    ret_validate_openstack_dashboard_conf=$?
    validate_sha256_local_settings_py
    ret_validate_sha256_local_settings_py=$?

    echo "SHA256_OPENSTACK_DASHBOARD_CONF=${SHA256_OPENSTACK_DASHBOARD_CONF}, SHA256_LOCAL_SETTINGS_PY=${SHA256_LOCAL_SETTINGS_PY}"

    # TODO: check django compressed and check the result

    if [ ${ret_validate_openstack_dashboard_conf} = 1 ] && [ ${ret_validate_sha256_local_settings_py} = 1 ]; then
        /usr/share/openstack-dashboard/manage.py compress
    fi


    return 0
}

validate_sha256_openstack_dashboard_conf() {
    validate_sha256 "${SHA256_PATH_OPENSTACK_DASHBOARD_CONF}" "${SHA256_OPENSTACK_DASHBOARD_CONF}"
    return $?
}

validate_sha256_local_settings_py() {
    validate_sha256 "${SHA256_PATH_LOCAL_SETTINGS_PY}" "${SHA256_LOCAL_SETTINGS_PY}"
    return $?
}

# Meanings of return values are...
#   0       : Checksums between previous one and current one are matched.
#   1       : Checksums between previous one and current one are mismatched.
#   (Others): Something went wrong.
validate_sha256() {
    local sha256_path="$1"
    local sha256_value="$2"
    local previous_sha256_value=

    if [ -f "${sha256_path}" ]; then
        read previous_sha256_value < "${sha256_path}"
        [[ "${previous_sha256_value}" == "${sha256_value}" ]] || return 1
        return 0
    fi

    echo -n "${sha256_value}" > "${sha256_path}"
    return 1
}

set_sha256_openstack_dashboard_conf() {
    set_sha256 "SHA256_OPENSTACK_DASHBOARD_CONF" "${PATH_OPENSTACK_DASHBOARD_CONF}" || return 1
}
set_sha256_local_settings_py() {
    set_sha256 "SHA256_LOCAL_SETTINGS_PY" "${PATH_LOCAL_SETTINGS_PY}" || return 1
}

set_sha256() {
    local name_of_val="$1"
    local file_path="$2"
    declare -a tmp_array=()

    tmp_array=($(sha256sum "${file_path}"))
    eval "${name_of_val}=${tmp_array[0]}"

    [[ -n $(eval echo "\$${name_of_val}") ]] || {
        echo -n "ERROR: Failed to get sha256sum from \"${file_path}\". Its value is ${name_of_val}="
        eval echo -n "\$${name_of_val}"
        echo "."
        return 1
    }
    return 0
}


main "$@"
