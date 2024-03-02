## Ansible
Replace the maste and worker ip with the correct one, existing one is the example one

in the bastion host, install ansible
```bash
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

install kubectl on bastion host
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
 
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

then in the bastion host, you need to have private key pem file for private vm and we will add that in our ssh config
```bash
ssh-agent bash 
ssh-add <private key file location>
```

now, to run the ansible, 
```bash
ansible-playbook -i inventory.ini install.yml
```

