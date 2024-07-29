# Stepwise Math Open edX Palm tutor build

- start date: 29-jul-2024
- docs: https://docs.tutor.edly.io/
- domain: staging.stepwisemath.ai

Migration from Palm on Kubernetes to AWS EC2 instance


Target server:

```bash
Host bedu
  HostName 52.14.129.223
  User ubuntu
  IdentityFile ~/.ssh/bastion.service.lawrencemcdaniel.pem
  IdentitiesOnly yes
```

## EC2 AMI

ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240701.1

## ubuntu packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install python3 python3-pip libyaml-dev python3-venv
# sudo add-apt-repository ppa:deadsnakes/ppa -y
```

## Docker installation

https://docs.docker.com/engine/install/ubuntu/

### Add Docker's official GPG key

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

### Install Docker CE

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose
sudo apt update
sudo usermod -a -G docker ubuntu
# DON'T FORGET TO logout!!!
sudo docker run hello-world
docker-compose version
```

## python virtual environment

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install setuptools
pip install "tutor[full]==16.1.8"
# tutor local launch
```

## install aws cli

```bash
sudo snap install aws-cli --classic
```
