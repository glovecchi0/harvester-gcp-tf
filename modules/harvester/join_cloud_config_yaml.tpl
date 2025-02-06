#cloud-config
scheme_version: 1
server_url: https://192.168.122.120:443
token: ${token}
os:
  hostname: ${hostname}
  password: ${password}
  ntp_servers:
  - 0.suse.pool.ntp.org
  - 1.suse.pool.ntp.org
install:
  mode: join
  management_interface:
    interfaces:
      - name: ens3
    default_route: true
    method: dhcp
    bond_options:
      mode: active-backup
      miimon: 100
  device: /dev/vda
  iso_url: http://192.168.122.1/harvester-${version}-amd64.iso
  tty: tty1,115200n8
