
```
host$ virsh edit ${DOMAIN_NAME}
```

```
<domain type='kvm'>
  ......
  <memoryBacking>
    <source type="memfd"/>
    <access mode="shared"/>
  </memoryBacking>
  ......
  <devices>
    ......
    <filesystem type="mount" accessmode="passthrough">
      <driver type="virtiofs"/>
      <source dir="/path/to/hostdir"/>
      <target dir="build_server_ansible"/>
      <address type="pci" domain="0x0000" bus="0x07" slot="0x00" function="0x0"/>
    </filesystem>
  </devices>
```

```
vm$ sudo mkdir /build_server_ansible
vm$ sudo mount -t virtiofs build_server_ansible /build_server_ansible

vm$ cat << 'EOF' > /etc/fstab
build_server_ansible /build_server_ansible virtiofs defaults 0 1
EOF
```

