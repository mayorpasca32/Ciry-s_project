# configured aws provider with proper credentials
provider "aws" {
  region     = var.region
  profile    = "devops"
}


# Create a VPC

resource "aws_vpc" "genomics_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "genomics_vpc"
  }
}

# Create a Subnet

resource "aws_subnet" "genomics_subnet" {
  vpc_id            = aws_vpc.genomics_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "genomics-subnet"
  }
}

#Create the Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "genomics_igw" {
  vpc_id = aws_vpc.genomics_vpc.id

  tags = {
    Name = "genomics_igw"
  }
}

# Create a Route Table
resource "aws_route_table" "genomicsRT" {
  vpc_id = aws_vpc.genomics_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.genomics_igw.id
  }

  tags = {
    Name = "genomicsRT"
  }
}


#Associate the subnet with the Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.genomics_subnet.id
  route_table_id = aws_route_table.genomicsRT.id
}

# Create a Security Group for the EC2 Instance
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow webserver inbound traffic"
  vpc_id      = aws_vpc.genomics_vpc.id

  ingress {
    description = "Web Traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #cidr_blocks = ["${var.my_ip}/32"]
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # Any ip address/ any protocol
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_tls"
  }
}

# use data source to get a registered ubuntu ami
data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Create the EC2 instance and assign key pair
resource "aws_instance" "firstinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.genomics_subnet.id
  key_name               = "Genomics_key_pair"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("install_jenkins.sh")}"


  tags = {
    Name = "Jenkins_Server"
  }
}


resource "aws_instance" "secondinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.genomics_subnet.id
  key_name               = "Genomics_key_pair"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("install_tomcat.sh")}"
  


  tags = {
    Name = "Tomcat_Server"
  }
}



# print the url of the jenkins server
output "Jenkins_website_url" {
  value     = join ("", ["http://", aws_instance.firstinstance.public_ip, ":", "8080"])
  description = "Jenkins Server is firstinstance"
}

# print the url of the tomcat server
output "Tomcat_website_url2" {
  value     = join ("", ["http://", aws_instance.secondinstance.public_ip, ":", "8080"])
  description = "Tomcat Server is secondinstance"
}
