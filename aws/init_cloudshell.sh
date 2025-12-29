#!/bin/bash

install_eksctl() {
  # for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
  ARCH=amd64
  PLATFORM=$(uname -s)_$ARCH

  curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

  # (Optional) Verify checksum
  curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

  tar -xzf eksctl_$PLATFORM.tar.gz && rm -f eksctl_$PLATFORM.tar.gz

  install -m 0755 eksctl ~/.local/bin && rm -f eksctl
}

install_helm() {
  ARCH=amd64
  PLATFORM=$(uname -s | tr A-Z a-z)-$ARCH

  LATEST=$(curl -L --silent --show-error --fail https://get.helm.sh/helm4-latest-version 2>&1 || true)

  curl -sLO "https://get.helm.sh/helm-${LATEST}-${PLATFORM}.tar.gz"

  # (Optional) Verify checksum
  curl -sL "https://get.helm.sh/helm-${LATEST}-${PLATFORM}.tar.gz.sha256sum" | sha256sum --check

  tar -xzf helm-$LATEST-$PLATFORM.tar.gz && rm -f helm-$LATEST-$PLATFORM.tar.gz

  install -m 0755 $PLATFORM/helm ~/.local/bin && rm -rf ./$PLATFORM

}

bash_completion() {
  mkdir -p ~/.local/share/bash-completion ~/.bashrc.d
  curl -sL https://raw.githubusercontent.com/scop/bash-completion/2.x/bash_completion -o ~/.local/share/bash-completion/bash_completion

  cat << EOF > ~/.bashrc.d/bashrc
# Load local bash-completion
if [ -f ~/.local/share/bash-completion/bash_completion ]; then
    source ~/.local/share/bash-completion/bash_completion
fi

# Eksctl completion
if command -v eksctl >/dev/null 2>&1; then
    source <(eksctl completion bash)
fi

# Helm completion
if command -v helm >/dev/null 2>&1; then
    source <(helm completion bash)
fi

# Kubectl completion
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
fi
EOF
}

main() {
  if ! command -v eksctl > /dev/null 2>&1; then
    install_eksctl
  fi

  if ! command -v helm > /dev/null 2>&1; then
    install_helm
  fi

  bash_completion
}

main
