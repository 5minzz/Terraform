#########provider 지정###############

provider "aws" {
  region = "ap-northeast-2"
}

#################### ec-2용 ssh키페어 정의 ####################

resource "aws_key_pair" "omin-terraform-key" {
  key_name = "omin-terraform-key"
  public_key = file("C:\\Users\\5458z\\terraform_study\\id_rsa.pub")
}

#################### VPC 생성 ####################
resource "aws_vpc" "omin-terraform-VPC" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "omin-terraform-VPC"
  }
}
#################### Internet Gateway 생성 ####################
resource "aws_internet_gateway" "omin-terraform-IGW" {
  vpc_id = aws_vpc.omin-terraform-VPC.id
  tags = {
    Name = "omin-terraform-IGW"
  }
}
#################### Public Subnet 생성 ####################
resource "aws_subnet" "omin-terraform-Public-Subnet" {
  vpc_id     = aws_vpc.omin-terraform-VPC.id
  cidr_block = "10.1.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "omin-terraform-Public-Subnet"
  }
}
#################### Public Routing Table 생성 ####################
resource "aws_route_table" "omin-terraform-Public-RT" {
  vpc_id = aws_vpc.omin-terraform-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.omin-terraform-IGW.id
  }

  tags = {
    Name = "omin-terraform-Public-RT"
  }
}
##################### Subnet 연결 ########################
resource "aws_route_table_association" "Public-RT-Association1" {
  subnet_id      = aws_subnet.omin-terraform-Public-Subnet.id
  route_table_id = aws_route_table.omin-terraform-Public-RT.id
}

############## 보안그룹(Security Groups) 정의 ################

resource "aws_security_group" "omin-terraform-SG" {
  vpc_id = aws_vpc.omin-terraform-VPC.id
  name   = "omin-terraform-SG"

  tags = {
    Name = "omin-terraform-SG"
  }
}

# EC-2 SG 인바운드 규칙 #  
resource "aws_security_group_rule" "omin-terraform-SG-SSH" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.omin-terraform-SG.id
}

resource "aws_security_group_rule" "omin-terraform-SG-ping" {
  type        = "ingress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.omin-terraform-SG.id
}


# EC-2 SG 아웃바운드 규칙 #
resource "aws_security_group_rule" "omin-terraform-SG-Out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.omin-terraform-SG.id
}

########## ec-2 생성 ###########

resource "aws_instance" "omin-terraform-test-EC2"{
  ami                    = "ami-0fd0765afb77bcca7"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.omin-terraform-Public-Subnet.id
  vpc_security_group_ids = [aws_security_group.omin-terraform-SG.id]
  key_name               = aws_key_pair.omin-terraform-key.key_name

  availability_zone           = "ap-northeast-2a"
  associate_public_ip_address = true

    tags = {
    Name = "omin-terraform-test-EC2"
  }
}