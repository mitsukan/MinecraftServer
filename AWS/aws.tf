provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_security_group" "mc_sg" {
  name        = "minecraft_sg"
  description = "Allow minecraft & SSH access"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Minecraft
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Minecraft SG"
  }
}

resource "aws_instance" "web" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  # Keypair for EC2 instance
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids      = ["${aws_security_group.mc_sg.id}"]
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo usermod -a -G docker ec2-user",
      "sudo service docker start",
      "sudo chkconfig docker on",
    #   "sudo yum install -y git",
    #   "sudo sed -i 's|ExecStart=/usr/bin/dockerd $OPTIONS $DOCKER_STORAGE_OPTIONS $DOCKER_ADD_RUNTIMES|ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock|g' /usr/lib/systemd/system/docker.service",
    #   "sudo systemctl daemon-reload",
    #   "sudo service docker restart",
    #   "sudo docker swarm init"
    ]
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    password    = ""
    private_key = "${file("~/.ssh/minecraftkp.pem")}"
    host        = "${self.public_ip}"
  }

  tags = {
    "Name" = "Minecraft_server"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = "${aws_instance.web.id}"
  allocation_id = "${var.eip_allocation_id}"
}
