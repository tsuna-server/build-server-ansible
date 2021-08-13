# build-server-ansible
This is a repository to build servers.

# Usage
## On Python virtual env
You can prepare an environment with Python virtualenv like below.

```
$ . ./venv/bin/activate
(venv) $ pip -r requirements.txt
```

`ansible-playbook` can run with checking mode by adding `--check` option like below.

```
(venv) $ ansible-playbook -i production -l [hostname or group name] --check sites.yml
// Some options might be needed like `--ask-pass`, `--become` or `--ask-become-pass` depending on your environment.
```

If NO errors were reported then you can run Ansible without the option `--check`.

```
(venv) $ ansible-playbook -i production -l <hostname or group name> sites.yml
```

## Run with docker
```
# docker build -t tsutomu/build-server-ansible ./docker
```

```
# docker run --rm \
    --add-host dev-private-router01:<IP> \
    --volume ${PWD}:/opt/ansible \
    --volume /path/toprivate-key:/private-key \
    -ti tsutomu/build-server-ansible \
    develop dev-private-router01
```


