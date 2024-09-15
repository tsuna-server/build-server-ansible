#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

main() {
    local version_of_python="${1:-3.12.5}"
    cd "${SCRIPT_DIR}"

    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" || {
        echo "ERROR: Failed to initialize pyenv" 1>&2
        return 1
    }

    pipenv --python ${version_of_python} || {
        echo "ERROR: Failed to switch version of Python \"${version_of_python}\" in \"${PWD}\"" 1>&2
        return 1
    }

    pipenv install || {
        echo "ERROR: Failed to install dependencies with command \"pipenv install\" in \"${PWD}\"" 1>&2
        return 1
    }

    pipenv run main || {
        echo "ERROR: Failed to complete test cases \"pipenv run main\" in \"${PWD}\" due to previous errors" 1>&2
        return 1
    }

    return 0
}

main "$@"
