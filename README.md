# build-server-ansible
This is a repository to build servers.

# Usage
## On Python virtual env
You can prepare an environment with Python virtualenv like below.

```shell
$ . ./venv/bin/activate
(venv) $ pip -r requirements.txt
```

`ansible-playbook` can run with checking mode by adding `--check` option like below.

```shell
(venv) $ ansible-playbook -i production -l [hostname or group name] --check sites.yml
// Some options might be needed like `--ask-pass`, `--become` or `--ask-become-pass` depending on your environment.
```

If NO errors were reported then you can run Ansible without the option `--check`.

```shell
(venv) $ ansible-playbook -i production -l <hostname or group name> sites.yml
```

# Tags
This section explains patterns of specifying `--tags` (or `--skip-tags`) that you might want to specify frequently.

## Specifying no tags -> Run all tasks
If you want to run all tasks in this ansible, you can specify no tags.

* Run all tasks
```shell
$ ansible-playbook -i production -l <hostname or group name> sites.yml
```

## Skip modifying hosts
If you want to skip modifying `/etc/hosts` by this ansible-playbook because you already prepare it on your own for example, you can specify a tag like below.
You can specify nodes of controller or compute at `<hostname or group name>`.

```shell
$ ansible-playbook -i production -l <hostname or group name> --skip-tags role_hosts sites.yml
```

## Run only discover_hosts
If you want to run only a role `nova_discover_hosts` after you add a new compute node into a cluster that you already created, you can specify a tag like below.

* Run only a role `nova_discover_hosts`
```shell
$ ansible-playbook -i production -l <hostname or group name> --tags role_nova_discover_hosts
```

**Note:**  
If you want to add new compute that is not set up any OpenStack environment yet, you should run this ansible by specifying only compute node like below.
```shell
$ # This command assumes that you already set compute node as named "compute01".
$ ansible-playbook -i production -l compute01 --skip-tags role_hosts sites.yml
```

This instruction will only be used if you already set compute node as OpenStack compute node but not belonging the OpenStack environment yet.

Note: If you want to add new compute node from that is not to set up any OpenStack enfironment, you should run this ansible by spedifying only compute node like below.
This instruction will be used rary.

# Run with docker
You can run this ansible-playbook easily by using `tsutomu/ansible-runner`.

## Run with docker with specified options
You can specify options with docker like below.
You can spedify `--skip-tags` for example.

```shell
# docker run --rm \
    --add-host dev-private-router01:<IP> \
    --volume ${PWD}:/opt/ansible \
    --volume /path/to/private-key:/private-key \
    -ti tsutomu/ansible-runner \
    --user ubuntu -i production -l dev-private-router01:dev-compute01 --skip-tags role_hosts site.yml
```

