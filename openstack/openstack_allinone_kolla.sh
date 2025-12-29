#!/bin/bash
set -e

# Do manually
# sudo sed -i '$a kolla    ALL=(ALL)    NOPASSWD:ALL' /etc/sudoers
# sudo sed -i 's/dhcp4: true/dhcp4: no/' /etc/netplan/00-installer-config.yaml && sudo netplan apply
# sudo sed -ri 's/GRUB_CMDLINE_LINUX="(.*)"/GRUB_CMDLINE_LINUX="\1 net.ifnames=0 biosdevname=0"/' /etc/default/grub && sudo update-grub
# sudo reboot

# Clear Environment
rm -rf venv
sudo rm -rf /etc/kolla

# Install required packages
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt -y install git python3-dev libffi-dev python3-venv gcc libssl-dev git python3-pip &>/dev/null

# Configure pip source
mkdir -p "$HOME"/.pip
cat >"$HOME"/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = tuna.tsinghua.edu.cn
EOF

# Create virtual environment
python3 -m venv "$HOME"/venv
source "$HOME"/venv/bin/activate
pip install -U pip
pip install 'ansible>=6,<8'
pip install git+https://opendev.org/openstack/kolla-ansible@stable/2023.1

# Create Ansible Configuration file
cat >"$HOME"/ansible.cfg <<EOF
[defaults]
host_key_checking=False
pipelining=True
forks=100
EOF

# Customize kolla configuration
sudo mkdir /etc/kolla
sudo chown "$USER":"$USER" /etc/kolla
cp "$HOME"/venv/share/kolla-ansible/etc_examples/kolla/* /etc/kolla/
cp "$HOME"/venv/share/kolla-ansible/ansible/inventory/all-in-one .

echo '---
 
###################
# Ansible options
###################
 
workaround_ansible_issue_8743: yes
 
###############
# Kolla options
###############
 
config_strategy: "COPY_ALWAYS"
kolla_base_distro: "ubuntu"
openstack_release: "2023.1"
kolla_internal_vip_address: "192.168.88.99"
 
##############################
# Neutron - Networking Options
##############################
 
network_interface: "eth0"
neutron_external_interface: "eth1"
neutron_plugin_agent: "openvswitch"
 
###################
# OpenStack options
###################
 
enable_glance: "{{ enable_openstack_core | bool }}"
enable_haproxy: "no"
enable_keystone: "{{ enable_openstack_core | bool }}"
enable_mariadb: "yes"
enable_memcached: "yes"
enable_neutron: "{{ enable_openstack_core | bool }}"
enable_nova: "{{ enable_openstack_core | bool }}"
enable_aodh: "yes"
enable_ceilometer: "yes"
enable_cinder: "yes"
enable_cinder_backend_lvm: "yes"
enable_gnocchi: "yes"
enable_gnocchi_statsd: "yes"
enable_grafana: "yes"
enable_grafana_external: "{{ enable_grafana | bool }}"
enable_heat: "{{ enable_openstack_core | bool }}"
enable_horizon: "{{ enable_openstack_core | bool }}"
enable_nova_ssh: "yes"
enable_prometheus: "yes"
 
################################
# Cinder - Block Storage Options
################################
 
cinder_volume_group: "cinder-volumes"' | sudo tee /etc/kolla/globals.yml >/dev/null

kolla-genpwd
sudo sed -i "s/keystone_admin_password:.*/keystone_admin_password: kolla/" /etc/kolla/passwords.yml

# Create Cinder-Volumes
if sudo vgdisplay cinder-volumes &>/dev/null; then
    echo "cinder-volumes already exist!"
else
    sudo vgcreate cinder-volumes /dev/vdb
    echo "cinder-volumes create successfully!"
fi

# Deploy All-In-One OpenStack
kolla-ansible install-deps
kolla-ansible -i all-in-one bootstrap-servers
kolla-ansible -i all-in-one prechecks
kolla-ansible -i all-in-one deploy

# Add Kolla-Ansible Deployment User to Docker Group
sudo usermod -aG docker "$USER"

# Install OpenStack Command Line tools
pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/2023.1
pip install python-neutronclient -c https://releases.openstack.org/constraints/upper/2023.1
pip install python-glanceclient -c https://releases.openstack.org/constraints/upper/2023.1
pip install python-heatclient -c https://releases.openstack.org/constraints/upper/2023.1

# Generate OpenStack Admin Credentials
kolla-ansible post-deploy
cp /etc/kolla/admin-openrc.sh .

# Add alias for virtual environment
cat >>"$HOME"/.bashrc <<EOF
alias kolla='source venv/bin/activate;source admin-openrc.sh'
EOF

# kolla-ansible install-deps
# vim /home/kolla/.ansible/collections/ansible_collections/openstack/kolla/roles/docker/defaults/main.yml
# docker_apt_url: "https://mirrors.aliyun.com/docker-ce/linux/{{ ansible_facts.distribution | lower }}"
