# This is a role to manage Neutron

## Configuration files that will be modified
List configuration files and which node or network driver will modify configurations.
Contents of configurations that are shared between them will be handled by each templates of Ansible.

| File | Controller<br />and<br />Linux Bridge | Compute<br />and<br />Linux Bridge | Controller<br />and<br />OVN | Compute<br />and<br />OVN |
| - | - | - | - | - |
| /etc/neutron/neutron.conf | ✔️  | ✔️  | ✔️  | ✔️  |
| /etc/neutron/plugins/ml2/ml2_conf.ini | ✔️  | | ✔️  | |
| /etc/neutron/plugins/ml2/linuxbridge_agent.ini | ✔️  | ✔️  | | |
| /etc/neutron/l3_agent.ini | ✔️  | | | |
| /etc/neutron/dhcp_agent.ini | ✔️  | | | |
| /etc/neutron/metadata_agent.ini | ✔️  | | | |
| /etc/nova/nova.conf<br />([neutron] section) | ✔️  | ✔️  | ✔️  | ✔️  |

Neutron also requires configuring `/etc/nova/nova.conf` like below.
```ini
[neutron]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
service_metadata_proxy = true
metadata_proxy_shared_secret = METADATA_SECRET
```

See also: ["Configure the Compute service to use the Networking service" (in "Install and configure controller node")](https://docs.openstack.org/neutron/xena/install/controller-install-ubuntu.html)  

It will modified in nova role in this Ansible.

