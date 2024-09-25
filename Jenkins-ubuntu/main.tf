provider "aws" {
  region = "us-east-1"  # Adjust as needed
}

resource "aws_instance" "jenkins_server" {
  ami           = "ami-0e86e20dae9224db8"  # Ubuntu 22.04 LTS AMI (adjust based on region)
  instance_type = "t2.large"
  key_name      = "project"  # Replace with your key pair
  tags = {
    Name = "Jenkins-Server"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Update the system
    sudo apt update -y

    # Install dependencies
    sudo apt install -y fontconfig openjdk-17-jre apt-transport-https ca-certificates curl software-properties-common gnupg2

    # Install Jenkins
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins

    # Install Docker
    sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu  # Allowing 'ubuntu' user to run Docker commands
    sudo chmod 666 /var/run/docker.sock

    # Install AWS CLI v2
    sudo apt install unzip -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # Install kubectl
    sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    sudo apt install gh -y

    # Clean up installation files
    rm -f kubectl

    # Output Jenkins password
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
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
