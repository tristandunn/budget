package_update: true
package_upgrade: true
package_reboot_if_required: true

timezone: America/New_York

packages:
  - ca-certificates
  - curl
  - docker.io
  - git
  - vim

swap:
  filename: /swapfile
  size: 2G

users:
  - default
