#!/bin/bash
#
#	@Author: Harshit Sharma
#	@Email: harshitsharmahts@gmail.com
#	@Github: harshitsharmahts
#

function usage() {
	echo ""
	echo "Usage: ${0} [mode]"
	echo ""
	echo "Supported mode:"
	echo "  docker		Install docker on your machine."
	echo "  docker-compose	Install docker-compose on your machine."
	echo "  remove		Removes the docker from the machine."
}

lsb_release -is > /dev/null 2>&1
if [ $? -ne 0 ]; then
	sudo yum -y install redhat-lsb-core || sudo apt-get -y install lsb-release
fi

export OPERATING_SYSTEM=`lsb_release -is | tr [:upper:] [:lower:]`
export ARCHITECTURE=`uname -m`

if [ "${ARCHITECTURE}" == "x86_64" ]; then
	ARCHITECTURE="amd64"
fi

case $OPERATING_SYSTEM in
	centos|redhatenterpriseserver)
		export INSTALL="sudo yum -y install"
		export REMOVE="sudo yum remove"
		export UPDATE="sudo yum -y update"
		;;
	ubuntu|debian)
		export INSTALL="sudo apt-get -y install"
		export REMOVE="sudo apt-get remove"
		export UPDATE="sudo apt-get -y update"
		;;
	*)
		echo "Operating system not supported by script."
esac

function docker_install() {
	${UPDATE}
	install_dependencies
	add_gpg_key
	setup_stable_repository
	install_docker
	post_installation
	say_hello
	echo ""
	echo "Docker installed!"
}

function docker_compose_install() {
	echo "---> Installing docker-compose..."
	sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	echo ""
	echo "Docker-compose installed!"
	docker-compose --version
}

function docker_remove() {
	if [ "${OPERATING_SYSTEM}" == "centos" ] || [ "${OPERATING_SYSTEM}" == "redhatenterpriseserver" ]; then
		$REMOVE docker docker-ce docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker logrotate docker-engine
	else
		$REMOVE docker docker-engine docker.io containerd runc
	fi
}

function install_dependencies() {
	echo "---> Installing Dependencies..."
	if [ "${OPERATING_SYSTEM}" == "centos" ] || [ "${OPERATING_SYSTEM}" == "redhatenterpriseserver" ]; then
		$INSTALL unzip \
			yum-utils \
			device-mapper-persistent-data \
			lvm2
	else
		$INSTALL apt-transport-https \
			ca-certificates \
			curl \
			gnupg-agent \
			software-properties-common
	fi
	echo "install_dependencies END"
}

function add_gpg_key() {
	echo "---> adding GPG key..."
	if [ "${OPERATING_SYSTEM}" != "centos" ] && [ "${OPERATING_SYSTEM}" != "redhatenterpriseserver" ]; then
		curl -fsSL https://download.docker.com/linux/${OPERATING_SYSTEM}/gpg | sudo apt-key add -
	fi
}

function setup_stable_repository() {
	echo "---> setting up stable repository..."
	if [ "${OPERATING_SYSTEM}" == "centos" ] || [ "${OPERATING_SYSTEM}" == "redhatenterpriseserver" ]; then
		sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	else
		sudo add-apt-repository \
			"deb [arch=${ARCHITECTURE}] https://download.docker.com/linux/${OPERATING_SYSTEM} \
			$(lsb_release -cs) \
			stable"
	fi
}

function install_docker() {
	echo "---> update..."
	$UPDATE
	echo "---> installing docker-ce..."
	$INSTALL docker-ce docker-ce-cli containerd.io
}

function post_installation() {
	sudo usermod -aG docker $USER
	sudo systemctl stop docker
	sudo systemctl enable docker
	sudo systemctl restart docker
}

function say_hello() {
	echo "---> hello from docker..."
	sudo docker run hello-world
}


export OPERATION=`echo $1 | tr [:upper:] [:lower:]`

case $OPERATION in
	docker)
		docker_install
	;;
	docker-compose)
		docker_compose_install
	;;
	remove)
		docker_remove
	;;
	*)
		usage;
esac

