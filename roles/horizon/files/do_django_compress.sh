#!/usr/bin/env bash
SHA256_PATH_OPENSTACK_DASHBOARD_CONF="/root/.sha256_openstack_dashboard_conf"
SHA256_PATH_LOCAL_SETTINGS_PY="/root/.sha256_local_settings_py"

PATH_OPENSTACK_DASHBOARD_CONF="/etc/apache2/conf-available/openstack-dashboard.conf"
PATH_LOCAL_SETTINGS_PY="/etc/openstack-dashboard/local_settings.py"

SHA256_OPENSTACK_DASHBOARD_CONF=
SHA256_LOCAL_SETTINGS_PY=

main() {
    local ret_validate_openstack_dashboard_conf ret_validate_sha256_local_settings_py ret_need_to_be_compressed

    set_sha256_openstack_dashboard_conf || return 1
    set_sha256_local_settings_py        || return 1

    validate_sha256_openstack_dashboard_conf
    ret_validate_openstack_dashboard_conf=$?
    if [ ! ${ret_validate_openstack_dashboard_conf} = 0 ] && [ ! ${ret_validate_openstack_dashboard_conf} = 1 ]; then
        echo "ERROR: Result of checking sha256 of \"${PATH_OPENSTACK_DASHBOARD_CONF}\". Return code is \"${ret_validate_openstack_dashboard_conf}\"."
        return 1
    fi

    validate_sha256_local_settings_py
    ret_validate_sha256_local_settings_py=$?
    if [ ! ${ret_validate_sha256_local_settings_py} = 0 ] && [ ! ${ret_validate_sha256_local_settings_py} = 1 ]; then
        echo "ERROR: Result of checking sha256 of \"${PATH_LOCAL_SETTINGS_PY}\". Return code is \"${ret_validate_sha256_local_settings_py}\"."
        return 1
    fi

    # TODO: check django compressed and check the result
    need_to_be_compressed
    ret_need_to_be_compressed=$?
    if [ ! ${ret_need_to_be_compressed} = 0 ] && [ ! ${ret_need_to_be_compressed} = 1 ]; then
        echo "ERROR: Result of checking need to be compressed[need_to_be_compressed()]. Return code is \"${ret_need_to_be_compressed}\"."
        return 1
    fi

    echo "DEBUG: SHA256_OPENSTACK_DASHBOARD_CONF=${SHA256_OPENSTACK_DASHBOARD_CONF}, SHA256_LOCAL_SETTINGS_PY=${SHA256_LOCAL_SETTINGS_PY}, ret_validate_openstack_dashboard_conf=${ret_validate_openstack_dashboard_conf}, ret_validate_sha256_local_settings_py=${ret_validate_sha256_local_settings_py}, ret_need_to_be_compressed=${ret_need_to_be_compressed}"

    if ([ ${ret_validate_openstack_dashboard_conf} = 1 ] || [ ${ret_validate_sha256_local_settings_py} = 1 ]) && [ ${ret_need_to_be_compressed} = 0 ]; then
        echo "INFO: /usr/share/openstack-dashboard/manage.py compress"
        /usr/share/openstack-dashboard/manage.py compress || {
            echo "ERROR: Failed to the command \"/usr/share/openstack-dashboard/manage.py compress\". Its return code is \"$?\"" >&2
            return 1
        }
    fi

    return 0
}

# Check whether djsngo need to be compressed.
# return 0: Need to be compressed
# return 1: Need not to be compressed
need_to_be_compressed() {
    # A toric is refere to: https://github.com/cookiecutter/cookiecutter-django/blob/a63278fb4ec4e3359202603777411ea16359babe/%7B%7Bcookiecutter.project_slug%7D%7D/compose/production/django/start#L9-L28
    python3 << EOF
import sys
from environ import Env

env = Env(COMPRESS_ENABLED=(bool, True))
if env('COMPRESS_ENABLED'):
    sys.exit(0)
else:
    sys.exit(1)
EOF
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
        [[ "${previous_sha256_value}" == "${sha256_value}" ]] || {
            echo "INFO: Updating sha256 file \"${sha256_path}\" with value \"${sha256_value}\""
            echo -n "${sha256_value}" > "${sha256_path}"
            return 1
        }
        return 0
    fi

    echo "INFO: Creating sha256 file \"${sha256_path}\" with value \"${sha256_value}\""
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
