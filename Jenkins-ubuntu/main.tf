provider "aws" {
  region = "us-east-1"  # Adjust as needed
}

resource "aws_instance" "jenkins_server" {
  ami           = "ami-0e86e20dae9224db8"  # Ubuntu 22.04 LTS AMI (adjust based on region)
  instance_type = "t2.large"
  key_name      = "project"           # Replace with your key pair
  tags = {
    Name = "Jenkins-Server"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install fontconfig openjdk-17-jre -y
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install jenkins -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
  EOF

  security_groups = [aws_security_group.jenkins_sg.name]
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}