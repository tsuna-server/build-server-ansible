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

## Patterns of tasks that you might want to run
This section explains patterns of specifying tags and other options that you might want to run.

### Run all tasks
If you want to run all tasks in this ansible, you should not specify any tags.
You can specify nodes of controller or compute at `<hostname or group name>`.

* Run all tasks
```
$ # (Without any tags should be specified)
$ ansible-playbook -i production -l <hostname or group name> sites.yml
```

### Skip modifying hosts
If you want to skip modifying `/etc/hosts` by this ansible-playbook because you already prepare it on your own for example, you can specify a tag like below.
You can specify nodes of controller or compute at `<hostname or group name>`.

```
$ ansible-playbook -i production -l <hostname or group name> --skip-tags role_hosts sites.yml
```

### Run only discover_hosts
If you want to run only a role `nova_discover_hosts` after you add a new compute node into a cluster that you already created, you can specify a tag like below.

* Run only a role `nova_discover_hosts`
```
$ ansible-playbook -i production -l <hostname or group name> --tags role_nova_discover_hosts
```

# Run with docker
Docker container to run this ansible is already prepared.
You can run this ansible-playbook easily by using it.

```
# docker build -t tsutomu/build-server-ansible ./docker
```

```
# docker run --rm \
    --add-host dev-private-router01:<IP> \
    --volume ${PWD}:/opt/ansible \
    --volume /path/to/private-key:/private-key \
    -ti tsutomu/build-server-ansible \
    develop dev-private-router01
```

