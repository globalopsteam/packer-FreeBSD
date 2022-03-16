packer-FreeBSD
==============

FORKED for Libvirt/KVM/Qemu

This repository contains the necessary tools to build a Vagrant-ready
FreeBSD virtual machine using Packer.

The default pkg was 'quarterly', now 'latest'.

There are [official FreeBSD] VMs available from the Vagrant Cloud.

Prerequisites
--------------

- [Packer]

- [Vagrant]

- [Libvirt]

Instructions
------------

To create a box:

1.  Clone this repository:

        $ git clone https://github.com/bretton/packer-FreeBSD.git
        $ cd packer-FreeBSD

2.  Configure your own `variables.json` from `variables.json.sample`

        $ cp variables.json.sample variables.json
        $ vi variables.json

3.  Build the box:

        $ packer build -only=qemu -var 'accelerator=kvm' -var-file=variables.json template.json

4.  Add it to the list of Vagrant boxes.  See
    [Handling `.iso` and `.box` files](#handling-iso-and-box-files) for
    more information.

        $ vagrant box add builds/FreeBSD-13.0-RELEASE-amd64.box --name FreeBSD-13.0-RELEASE-amd64

Sample `Vagrantbox` file
------------------------
The following brings up 3 servers:
* www
* db
* ansiblevm (use this for clean dev environment to run additional provisioning scripts)

The following Vagrantfile is customised for Qemu/Libvirt so use of virtio-scsi for disk and virtio-net for network are necessary. 

This might not work on Redhat-based systems.


```ruby
script = <<-SCRIPT
  sed -i '' "s/Vagrant/$(hostname -s)/g" /usr/local/etc/mDNSResponderServices.conf
  service mdnsresponderposix restart
SCRIPT

ansible_raw_arguments = []

Vagrant.configure("2") do |config|
  config.vm.define "www.local", primary: true do |node|
    node.vm.hostname = 'www.local'
    node.vm.box = "FreeBSD-${FREEBSD_VERSION}-RELEASE-amd64"
    node.vm.synced_folder '.', '/vagrant', disabled: true
    node.vm.boot_timeout = 600
    node.vm.provider "libvirt" do |libvirt|
      libvirt.disk_driver :bus => 'virtio-scsi', :cache => 'none'
      libvirt.driver = "kvm"
      libvirt.description = "www server"
      libvirt.memory = "2048"
      libvirt.cpus = "1"
      libvirt.nic_model_type = 'virtio-net'
      libvirt.management_network_mode = 'nat'
      libvirt.graphics_port = 5901
      libvirt.graphics_ip = '0.0.0.0'
      libvirt.video_type = 'qxl'
    end
  end
  config.vm.define "db.local", primary: false do |node|
    node.vm.hostname = 'db.local'
    node.vm.box = "FreeBSD-${FREEBSD_VERSION}-RELEASE-amd64"
    node.vm.synced_folder '.', '/vagrant', disabled: true
    node.vm.boot_timeout = 600
    node.vm.provider "libvirt" do |libvirt|
      libvirt.disk_driver :bus => 'virtio-scsi', :cache => 'none'
      libvirt.driver = "kvm"
      libvirt.description = "db server"
      libvirt.memory = "4096"
      libvirt.cpus = "2"
      libvirt.management_network_mode = 'nat'
      libvirt.nic_model_type = 'virtio-net'
      libvirt.graphics_port = 5902
      libvirt.graphics_ip = '0.0.0.0'
      libvirt.video_type = 'qxl'
    end
  end
  config.vm.define "ansible.local", primary: false do |node|
    node.vm.hostname = 'ansible.local'
    node.vm.box = "FreeBSD-${FREEBSD_VERSION}-RELEASE-amd64"
    node.vm.synced_folder '.', '/vagrant', disabled: true
    node.vm.boot_timeout = 600
    node.vm.provider "libvirt" do |libvirt|
      libvirt.disk_driver :bus => 'virtio-scsi', :cache => 'none'
      libvirt.driver = "kvm"
      libvirt.description = "VM to run Ansible orchestration scripts against www and db"
      libvirt.memory = "2048"
      libvirt.cpus = "1"
      libvirt.management_network_mode = 'nat'
      libvirt.nic_model_type = 'virtio-net'
      libvirt.graphics_port = 5900
      libvirt.graphics_ip = '0.0.0.0'
      libvirt.video_type = 'qxl'
    end
    node.vm.provision 'ansible' do |ansible|
      ansible.compatibility_mode = '2.0'
      ansible.limit = 'all'
      ansible.playbook = 'site.yml'
      ansible.become = true
      ansible.verbose = '-vvv'
      ansible.raw_ssh_args = "-o ControlMaster=no -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=10 -o ConnectTimeout=30 -o ServerAliveInterval=5"
      ansible.groups = {
        "all" => ["www.local", "db.local", "ansible.local"],
        "all:vars" => {
          "ansible_python_interpreter" => "/usr/local/bin/python"
        },
      }
    end
  end
end

def private_key_path(server_name)
  provider = ENV['VAGRANT_DEFAULT_PROVIDER'] || 'libvirt'
  vagrant_dotfile_path = ENV['VAGRANT_DOTFILE_PATH'] || '.vagrant'

  "--private-key=#{vagrant_dotfile_path}/machines/#{server_name}/" \
    "#{provider}/private_key"
end
```

------------------------------------------------------------------------

### Build Options

Below is a sample `variables.json.sample` file:

```json
{
  "cpus": "1",
  "disk_size": "32G",
  "memory": "1024",
  "revision": "13.0",
  "branch": "-RELEASE",
  "build_date": "",
  "git_commit": "",
  "directory": "releases",
  "arch": "amd64",
  "guest_os_type": "FreeBSD_64",
  "filesystem": "zfs",
  "mirror": "https://download.freebsd.org/ftp",
  "rc_conf_file": ""
}
```

The following variables can be set:

-   `cpus` is the number of CPUs assigned.  _Default:_ `1`

-   `disk_size` is the HDD size in megabytes.  _Default:_ `32G`

-   `memory` is the amount of RAM in megabytes assigned.  _Default:_
    `1024`

-   `revision` is the FreeBSD revision number.  _Default:_ `13.0`

-   `branch` used in conjunction with `build_date`, `git_commit` and
    `directory`.  _Default:_ `-RELEASE`

    See FreeBSD's [Release Branches] for more information.  Possible
    values are:

    | Branch                  | Directory   |
    | ------                  | ---------   |
    | `-CURRENT`              | `snapshots` |
    | `-STABLE`               | `snapshots` |
    | `-ALPHA1`, `-ALPHA2`, … | `snapshots` |
    | `-PRERELEASE`           | `snapshots` |
    | `-BETA1`, `-BETA2`, …   | `releases`  |
    | `-RC1`, `-RC2`, …       | `releases`  |
    | `-RELEASE`              | `releases`  |

-   `arch` is the target architecture (`i386` or `amd64`).  _Default:_
    `amd64`

-   `guest_os_type` (VirtualBox) used in conjunction with `arch`
    (`FreeBSD` or `FreeBSD_64`).  See [packer's
    documentation](https://www.packer.io/docs/builders/virtualbox-iso.html#guest_os_type).
    _Default:_ `FreeBSD_64`

-   `filesystem` is the file system type (`ufs` or `zfs`).  _Default:_
    `zfs`

-   `mirror` is the preferred FreeBSD mirror.  _Default:_
    `https://download.freebsd.org/ftp`

-   `rc_conf_file` is the file where `rc.conf` parameters are stored.
    _Default: empty_ .  Possible values are:

    | Value    | File                                          |
    | -----    | ----                                          |
    |          | `/etc/rc.conf`                                |
    | `local`  | `/etc/rc.conf.local` (Its use is discouraged) |
    | `vendor` | `/etc/defaults/vendor.conf`                   |
    | `name`   | `(/usr/local)/etc/rc.conf.d/<name>`           |

Create a `variables.json` file overriding the default
values, and invoke:

    $ packer build -var-file="variables.json" template.json

or for Qemu/KVM specifically

    $ PACKER_BUILDER_TYPE="qemu" packer build -only=qemu -var 'accelerator=kvm' -var-file="variables.json" template.json

You can also select which components you wish to install.  By default,
it runs the following provisioning scripts:

| Name         | Description                                                               |
| ----         | -----------                                                               |
| [`update`]   | Updates to the latest patch level (if applicable) and the latest packages |
| [`vagrant`]  | Vagrant-related configuration                                             |
| [`zeroconf`] | Enables zero-configuration networking                                     |
| [`ansible`]  | Installs python and CA Root certificates                                  |
| [`vmtools`]  | Virtual Machine-specific utilities                                        |
| [`cleanup`]  | Cleanup script (must be called last)                                      |

The following scripts are also available:

| Name                | Description                       |
| ----                | -----------                       |
| [`hardening`]       | Provides basic hardening options  |
| [`simplehardening`] | Provides subset hardening options |
| [`ports`]           | Installs the FreeBSD ports tree   |

### Handling `.iso` and `.box` files

Packer will automatically download the `.iso` image if it does not find
the right one under the `iso` directory.  Optionally, you can download
the `.iso` image and save it to the `iso` directory.

`.box` files will be created under the `builds` directory.

[official FreeBSD]: https://app.vagrantup.com/freebsd
[Release Branches]: https://www.freebsd.org/doc/en/books/dev-model/release-branches.html
[Packer]: https://www.packer.io/docs/installation.html
[Vagrant]: https://www.vagrantup.com/downloads.html
[VirtualBox]: https://www.virtualbox.org/wiki/Downloads
[VMWare Fusion]: http://www.vmware.com/products/fusion/
[Libvirt]: https://libvirt.org/
[`ansible`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/ansible.sh
[`cleanup`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/cleanup.sh
[`hardening`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/hardening.sh
[`simplehardening`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/simplehardening.sh
[`ports`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/ports.sh
[`update`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/update.sh
[`vagrant`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/vagrant.sh
[`vmtools`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/vmtools.sh
[`zeroconf`]: https://github.com/bretton/packer-FreeBSD/blob/main/scripts/zeroconf.sh
