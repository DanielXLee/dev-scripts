#!/bin/bash
# Support ubuntu 16.x, rhel 7.x

# Proxy server IP address, example: 23.43.56.32
PROXY_SERVER=${PROXY_SERVER:-}
# Proxy port, by default is 3128
PROXY_PORT=${PROXY_PORT:-3128}

# Setup apt proxy
function setup_apt_proxy() {
    cat >/etc/apt/apt.conf.d/91proxyconf<<EOF
Acquire::http::Proxy "http://${PROXY_SERVER}:${PROXY_PORT}/";
Acquire::ftp::proxy "ftp://${PROXY_SERVER}:${PROXY_PORT}/";
Acquire::https::proxy "https://${PROXY_SERVER}:${PROXY_PORT}/";
EOF
    sudo apt-get update
}

# Setup yum proxy
function setup_yum_proxy() {
    [[ ! -f /etc/yum.conf ]] && touch /etc/yum.conf
    if [[ $(cat /etc/yum.conf | grep -e ^proxy=) ]]; then
        echo proxy=http://${PROXY_SERVER}:${PROXY_PORT} >> /etc/yum.conf
    else
        sed -i "s/^proxy=.*/proxy=http://${PROXY_SERVER}:${PROXY_PORT}/" /etc/yum.conf
    fi
    setup_yum_base_repo
}

# Setup yum base repo
function setup_yum_base_repo() {
    cat > /etc/yum.repos.d/rpmfind.repo<<EOF
[Local-Rpmfind]
name=Rpmfind release 30 repository
baseurl=http://rpmfind.net/linux/fedora/linux/releases/30/Everything/x86_64/os
gpgcheck=0
enabled=1
EOF
}

# Setup wget proxy
function setup_wget_proxy() {
    which wget
    if [[ "$?" != "0" ]]; then
        [[ "$ID" == "ubuntu" || "$ID" == "debian" ]] && apt install wget
        [[ "$ID" == "centos" || "$ID" == "rhel" ]] && yum install wget -y
    fi
    if [[ ! -f /etc/wgetrc ]]; then
        touch /etc/wgetrc
    else
        cp /etc/wgetrc /etc/wgetrc_bak
    fi
    cat >/etc/wgetrc<<EOF
http_proxy=http://${PROXY_SERVER}:${PROXY_PORT}
https_proxy=https://${PROXY_SERVER}:${PROXY_PORT}
ftp_proxy=ftp://${PROXY_SERVER}:${PROXY_PORT}
EOF
}

# Install docker if not installed in ubuntu 16.04
function install_docker_ubt() {
    docker_version=$(dockerd --version 2>/dev/null)
    [[ "X$docker_version" != "X" ]] && return 0
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    export https_proxy=https://${PROXY_SERVER}:${PROXY_PORT}
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    unset https_proxy
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce
}

# Install docker if not installed in CentOS
function install_docker_centos() {
    docker_version=$(dockerd --version 2>/dev/null)
    [[ "X$docker_version" != "X" ]] && return 0
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install docker-ce -y
}

# Setup docker proxy
function setup_docker_proxy() {
    [[ "$ID" == "ubuntu" ]] && install_docker_ubt
    [[ "$ID" == "centos" ]] && install_docker_centos
    DOCKER_SERVICE_D="/etc/systemd/system/docker.service.d"
    [[ ! -d ${DOCKER_SERVICE_D} ]] && mkdir -p ${DOCKER_SERVICE_D}
    cat >${DOCKER_SERVICE_D}/http-proxy.conf<<EOF
[Service]
Environment="HTTP_PROXY=http://${PROXY_SERVER}:${PROXY_PORT}/" "NO_PROXY=localhost,127.0.0.1,docker-registry.somecorporation.com"
EOF
    cat >${DOCKER_SERVICE_D}/https-proxy.conf<<EOF
[Service]
Environment="HTTPS_PROXY=http://${PROXY_SERVER}:${PROXY_PORT}/" "NO_PROXY=localhost,127.0.0.1,docker-registry.somecorporation.com"
EOF
    systemctl daemon-reload
    systemctl restart docker
}

# Setup git http/https proxy
function setup_git_proxy() {
    which git
    if [[ "$?" != "0" ]]; then
        [[ "$ID" == "ubuntu" || "$ID" == "debian" ]] && apt install git
        [[ "$ID" == "centos" || "$ID" == "rhel" ]] && yum install git -y
    fi
    git config --global http.proxy http://${PROXY_SERVER}:${PROXY_PORT}
    git config --global https.proxy https://${PROXY_SERVER}:${PROXY_PORT}
    # Setup git ssh proxy
    which connect-proxy
    if [[ "$?" != "0" ]]; then
        [[ "$ID" == "ubuntu" || "$ID" == "debian" ]] && apt install connect-proxy
        if [[ "$ID" == "centos" || "$ID" == "rhel" ]]; then
            cd /tmp;wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
            cd /tmp;rpm -ivh epel-release-latest-7.noarch.rpm
            yum install connect-proxy -y
        fi
    fi
    [[ ! -f ~/.ssh/id_rsa ]] && ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''
    if [[ ! -f ~/.ssh/config ]]; then
        touch ~/.ssh/config
    else
        cp ~/.ssh/config ~/.ssh/config_bak
    fi
    cat >~/.ssh/config<<EOF
Host github.ibm.com
   ProxyCommand connect-proxy -H ${PROXY_SERVER}:${PROXY_PORT} %h %p
   IdentityFile ~/.ssh/id_rsa
   User git
EOF
}

# Setup npm proxy
function setup_npm_proxy() {
    which npm
    if [[ "$?" == "0" ]]; then
        npm config set proxy http://${PROXY_SERVER}:${PROXY_PORT}
        npm config set https-proxy https://${PROXY_SERVER}:${PROXY_PORT}
    fi
}

# Generate proxy conf
function genetate_proxy_conf() {
    cat > /root/proxy.conf <<EOF
export http_proxy=http://${PROXY_SERVER}:${PROXY_PORT}
export https_proxy=https://${PROXY_SERVER}:${PROXY_PORT}
export ftp_proxy=ftp://${PROXY_SERVER}:${PROXY_PORT}
EOF
}


#-------------------------------- Main -----------------------------#
[[ "X$PROXY_SERVER" == "X" ]] && echo "Missing proxy server ip, export PROXY_SERVER=xxx.xxx.xxx.xxx before run script." && exit 0

source /etc/os-release
# Common distributor ID: debian|ubuntu|devuan|centos|fedora|rhel
[[ "$ID" == "ubuntu" || "$ID" == "debian" ]] && setup_apt_proxy
[[ "$ID" == "centos" || "$ID" == "rhel" ]] && setup_yum_proxy
setup_wget_proxy
# setup_docker_proxy
# setup_git_proxy
# setup_npm_proxy
# genetate_proxy_conf

