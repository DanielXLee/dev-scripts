#!/usr/bin/env bash

msg() {
  printf '%b\n' "$1"
}

success() {
  msg "\33[32m[✔] ${1}\33[0m"
}

warning() {
  msg "\33[33m[✗] ${1}\33[0m"
}

error() {
  msg "\33[31m[✘] ${1}\33[0m"
}

title() {
  msg "\33[34m# ${1}\33[0m"
}

install-zsh() {
  title "Step 1: Install zsh and git if not exist"
  yum install zsh git -y
  # apt update && apt-get install zsh git -y

  title "Step 2: Install oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  title "Step 3: Install zsh plugin"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zdharma/history-search-multi-word.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/history-search-multi-word
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
  sed -i 's/^plugins=.*/plugins=(git z kubectl zsh-autosuggestions history-search-multi-word zsh-syntax-highlighting)/g' ~/.zshrc
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME=cloud/g' ~/.zshrc
}


install-required-pkgs() {
  # DOCKER=$(which docker 2>/dev/null)
  GO=$(which go 2>/dev/null)
  if [[ "X$GO" == "X" ]]; then
    title "Installing golang-go ..."
    wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.16
  fi

  KIND=$(which kind 2>/dev/null)
  if [[ "X$KIND" == "X" ]]; then
    title "Installing kind ..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
  fi

  HELM=$(which helm 2>/dev/null)
  if [[ "X$HELM" == "X" ]]; then
    title "Installing helm v3 ..."
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  fi

  KUBECTL=$(which kubectl 2>/dev/null)
  if [[ "X$KUBECTL" == "X" ]]; then
    title "Installing kubectl with version: $(curl -L -s https://dl.k8s.io/release/stable.txt)"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
  fi

  if [[ ! -f /usr/local/bin/kubecm ]]; then
    title "Installing kubecm ..."
    KUBECM_VERSION=0.15.3
    curl -Lo kubecm.tar.gz https://github.com/sunny0826/kubecm/releases/download/v${KUBECM_VERSION}/kubecm_${KUBECM_VERSION}_Linux_x86_64.tar.gz
    # linux & macos
    tar -zxvf kubecm.tar.gz kubecm
    mv kubecm /usr/local/bin/
  fi
}

KUBECM_VERSION=0.15.3
KIND_VERSION=

install-zsh
install-required-pkgs
