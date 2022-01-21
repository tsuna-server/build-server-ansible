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

Neutron also requires configuring `/etc/nova/nova.conf`.
It will modified in nova role in this Ansible.

