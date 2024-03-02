resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "example" {
  key_name   = "k3s-key-pair"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "k3s-key" {
  content  = tls_private_key.example.private_key_pem
  filename = "k3s-key.pem"
  file_permission = "0400"
}

# resource "aws_s3_object" "object" {
#   bucket = "poridhi-briefly-curiously-rightly-greatly-infinite-lion"
#   key    = "k3s-key.pem"
#   content = tls_private_key.example.private_key_pem
# }

resource "aws_instance" "public" {
  ami           = var.ami
  instance_type = var.instance_type_public
  count         = var.number_of_public_vm
  subnet_id     = var.public_subnet_id
  key_name      = "k3s-key-pair"
  security_groups = [
    var.security_group_id,
  ]
  tags = {
    Name = "${var.public_vm_tags[count.index]}"
  }
  provisioner "file" {
    source      = "../../env/dev/k3s-key.pem"
    destination = "/home/ubuntu/k3s-key.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      # private_key = file("../../env/dev/k3s-key.pem")
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
      # host        = aws_instance.public.*.public_ip[index(aws_instance.public.*.tags.Name, "bastion")]
    }
  }


  depends_on = [aws_key_pair.example, tls_private_key.example, local_file.k3s-key]
  # depends_on = [aws_key_pair.example, tls_private_key.example, aws_s3_object.object]
}

# data "aws_instance" "public"{
#   # instance_id = aws_instance.public[count.index].id
#   # filter {
#   #   name   = "tag:Name"
#   #   values = ["bastion"]
#   # }
# }


# resource "null_resource" "setup_bastion" {
#   depends_on = [aws_instance.public, data.aws_instance.public]
#   # depends_on = [aws_instance.public]

#   connection {
#     host = data.aws_instance.public.public_ip
#     type = "ssh"
#     user = "ubuntu"
#     private_key = tls_private_key.example.private_key_pem
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt-get update -y",
#       "sudo apt-get install software-properties-common -y",
#       "sudo apt-add-repository --yes --update ppa:ansible/ansible",
#       "sudo apt-get install ansible -y"
#     ]
#   }

#   # provisioner "file" {
#   #   source      = tls_private_key.example.private_key_pem
#   #   destination = "~/.ssh/authorized_keys"
#   # }
# }

# resource "null_resource" "bastion_upload" {
#   provisioner "file" {
#     source      = "../../env/dev/k3s-key.pem"
#     destination = "/home/ubuntu/k3s-key.pem"

#     connection {
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = file("../../env/dev/k3s-key.pem")
#       host        = aws_instance.public.*.public_ip[index(aws_instance.public.*.tags.Name, "bastion")]
#     }
#   }
# }

resource "aws_eip" "public" {
  count  = var.number_of_public_vm
  domain = "vpc"
}

resource "aws_eip_association" "public" {
  count         = var.number_of_public_vm
  instance_id   = aws_instance.public.*.id[count.index]
  allocation_id = aws_eip.public.*.id[count.index]
}

resource "aws_instance" "private" {
  ami           = var.ami
  instance_type = var.instance_type_private
  count         = var.number_of_private_vm
  subnet_id     = var.private_subnet_id
  key_name      = "k3s-key-pair"
  security_groups = [
    var.security_group_id,
  ]
  tags = {
    Name = "${var.private_vm_tags[count.index]}"
  }
  depends_on = [aws_key_pair.example, tls_private_key.example, local_file.k3s-key]
  # depends_on = [aws_key_pair.example, tls_private_key.example, aws_s3_object.object]
}

# data "aws_instances" "master" {
#   filter {
#     name   = "tag:Name"
#     values = ["master"]
#   }
# }

# data "aws_instances" "workers" {
#   filter {
#     name   = "tag:Name"
#     values = ["worker-1", "worker-2"]
#   } 
# }

# locals {
#   master_ip    = data.aws_instances.master.private_ips[0]
#   worker_ips   = data.aws_instances.workers.private_ips
# }

# resource "null_resource" "install_master" {
#   connection {
#     host        = local.master_ip
#     # ...
#   }

#   provisioner "remote-exec" {
#     inline = [ 
#       "curl -sfL https://get.k3s.io | sh -s - server --tls-san ${local.master_ip}"
#     ]
#   }
# }

# resource "null_resource" "copy_token" {
#   depends_on = [null_resource.install_master]

#   connection {
#     host        = aws_instance.bastion.public_ip
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file("~/k3s-key.pem")

#     bastion_host = aws_instance.bastion.public_ip
#     bastion_user = "ubuntu"  

#   }

#   provisioner "file" {
#     source      = "/var/lib/k3s/server/node-token"
#     destination = "/tmp/token"
#   }
# }


# data "local_file" "token" {
#   depends_on = [null_resource.copy_token]

#   filename = "/path/to/bastion/token"
# }

# resource "null_resource" "join_workers" {
#   count = length(local.worker_ips)

#   connection {
#     host = local.worker_ips[count.index]
#     # ... 
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "curl -sfL https://get.k3s.io | K3S_URL=https://${local.master_ip}:6443 K3S_TOKEN=${data.local_file.token.content} sh -"
#     ]
#   }
# }

# resource "null_resource" "run_local_exec" {
#   count = length(aws_instance.public)

#   provisioner "local-exec" {
#     command = aws_instance.public[count.index].tags.Name == "bastion" ? "ssh-agent bash -c 'ssh-add ../../env/dev/k3s-key.pem" : "echo 'Not a bastion host'"
#   }
# }

## Provisioning k3s master node
#resource "null_resource" "k3s_master" {
#  depends_on = [aws_instance.private]
#
#  provisioner "remote-exec" {
#    inline = [
#      "curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s - server",
#      "sudo cat /etc/rancher/k3s/k3s.yaml > /tmp/k3s-config.yaml",
#    ]
#
#    connection {
#      type        = "ssh"
#      host        = aws_instance.private[0].public_ip
#      user        = "ec2-user"
#      private_key = tls_private_key.example.private_key_pem
#    }
#  }
#
#  provisioner "local-exec" {
#    command = "scp -o StrictHostKeyChecking=no -i ${local_file.k3s-key.filename} ec2-user@${aws_instance.private[0].public_ip}:/tmp/k3s-config.yaml ."
#  }
#}
#
## Extracting master token
#data "local_file" "master_token" {
#  depends_on = [null_resource.k3s_master]
#
#  content  = <<-EOF
#    locals {
#      master_token = "$(grep 'token:' k3s-config.yaml | awk '{print $2}')"
#    }
#  EOF
#
#  filename = "master_token.tf"
#}
#
## Provisioning k3s worker nodes
#resource "null_resource" "k3s_worker" {
#  depends_on = [aws_instance.private, data.local_file.master_token]
#
#  count = 2
#
#  provisioner "remote-exec" {
#    inline = [
#      "curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.private[0].private_ip}:6443 K3S_TOKEN=${data.local_file.master_token.locals.master_token} sh -",
#    ]
#
#    connection {
#      type        = "ssh"
#      host        = aws_instance.private[count.index + 1].public_ip
#      user        = "ec2-user"
#      private_key = tls_private_key.example.private_key_pem
#    }
#  }
#}
