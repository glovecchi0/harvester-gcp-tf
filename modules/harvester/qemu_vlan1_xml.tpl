<network>
  <name>vlan1</name>
  <bridge name="virbr1"/>
  <forward mode="nat"/>
  <ip address="192.168.122.1" netmask="255.255.255.0">
    <tftp root="/srv/tftpboot"/>
    <dhcp>
      <range start="192.168.122.2" end="192.168.122.254"/>
      <bootp file="tftp://192.168.122.1/default.ipxe"/>
    </dhcp>
  </ip>
</network>
