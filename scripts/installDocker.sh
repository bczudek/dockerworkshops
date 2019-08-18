echo "Installing Docker"
export DOCKERURL="https://storebits.docker.com/ee/centos/sub-396efa35-0cee-43f6-9a04-98712c7b2edb"
sudo -E sh -c 'echo "$DOCKERURL/centos" > /etc/yum/vars/dockerurl'

sudo yum install -y yum-utils device-mapper-persistent-data lvm2

sudo -E yum-config-manager --add-repo "$DOCKERURL/centos/docker-ee.repo"

sudo yum -y install docker-ee docker-ee-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker bravo

sudo mkdir -p /etc/kubernetes

echo "Finished docker installation"