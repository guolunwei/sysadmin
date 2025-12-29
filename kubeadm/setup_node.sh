#!/bin/bash
#
# This script prepares environment for Kubernetes cluster on CentOS 7.
# Assuming docker is already installed.

set -eu

red="$( (
  /usr/bin/tput bold || :
  /usr/bin/tput setaf 1 || :
) 2>&-)"
plain="$( (/usr/bin/tput sgr0 || :) 2>&-)"

status() { echo ">>> $*" >&2; }
error() {
  echo "${red}ERROR:${plain} $*"
  exit 1
}
warning() { echo "${red}WARNING:${plain} $*"; }

available() { command -v "$1" > /dev/null; }

SUDO=
if [ "$(id -u)" -ne 0 ]; then
  # Running as root, no need for sudo
  if ! available sudo; then
    error "This script requires superuser permissions. Please re-run as root."
  fi

  SUDO="sudo"
fi

if [ $# -ne 1 ]; then
  echo "Usage: $0 <hostname>"
  exit 1
fi

if ! command -v docker; then
  error "Please install docker first."
fi

HOSTNAME="$1"
status "Setting hostname to $HOSTNAME"
hostnamectl set-hostname "$HOSTNAME"

status "Adding hostname to /etc/hosts"
cat << EOF | $SUDO tee -a /etc/hosts > /dev/null
192.168.88.101 master1
192.168.88.102 master2
192.168.88.103 master3
192.168.88.111 node1
192.168.88.112 node2
192.168.88.113 node3
EOF

status "Stopping and disabling firewalld"
if available firewalld; then
  $SUDO systemctl stop firewalld
  $SUDO systemctl disable firewalld
fi

status "Stopping and disabling NetworkManager"
if available NetworkManager; then
  $SUDO systemctl stop NetworkManager
  $SUDO systemctl disable NetworkManager
fi

status "Disabling SELinux"
if [ "$(getenforce)" == "Enforcing" ]; then
  warning "SELinux is enabled. Disabling SELinux..."
  $SUDO setenforce 0
  $SUDO sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
fi

status "Disabling swap"
$SUDO swapoff -a
$SUDO sed -i '/swap/d' /etc/fstab

status "Enabling and Loading Kernel modules"
cat << EOF | $SUDO tee /etc/modules-load.d/ipvs_docker.conf > /dev/null
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
br_netfilter
EOF
$SUDO systemctl restart systemd-modules-load.service

status "Adding Kernel settings"
cat << EOF | $SUDO tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
$SUDO sysctl --quiet --system

status "Adding Kubernetes repo"
cat << EOF | $SUDO tee /etc/yum.repos.d/kubernetes.repo > /dev/null
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

status "Installing Kubernetes packages"
yum install -y kubelet-1.23.17 kubeadm-1.23.17 kubectl-1.23.17

status "Modifying docker cgroup driver"
cat << EOF | $SUDO tee /etc/docker/daemon.json > /dev/null
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": [ "https://91efa3ce47eb43a387110210186f8803.mirror.swr.myhuaweicloud.com" ]
}
EOF
$SUDO systemctl daemon-reload
$SUDO systemctl restart docker

status "Starting kubelet service"
$SUDO systemctl enable kubelet && $SUDO systemctl start kubelet

status "$HOSTNAME is ready!"
