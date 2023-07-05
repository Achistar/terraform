# Define the provider
provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "ACHISTAR_VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ACHISTAR_VPC"
  }
}

# Create public subnet
resource "aws_subnet" "ACHISTAR_public_subnet" {
  vpc_id                  = aws_vpc.ACHISTAR_VPC.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ACHISTAR_Public_Subnet"
  }
  depends_on = [aws_vpc.ACHISTAR_VPC]
}

# Create private subnet
resource "aws_subnet" "ACHISTAR_private_subnet" {
  vpc_id                  = aws_vpc.ACHISTAR_VPC.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  tags = {
    Name = "ACHISTAR_Private_Subnet"
  }
depends_on = [aws_vpc.ACHISTAR_VPC]

}

# Create NAT gateway
resource "aws_eip" "my_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.ACHISTAR_public_subnet.id
  depends_on = [aws_subnet.ACHISTAR_public_subnet]

}

# Create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.ACHISTAR_VPC.id
}


# Create security groups
resource "aws_security_group" "ACHISTAR_public_sg" {
  name        = "ACHISTAR_public_sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.ACHISTAR_VPC.id

  # Inbound rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule to allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ACHISTAR_private_sg" {
  name        = "ACHISTAR_private_sg"
  description = "Security group for private instances"
  vpc_id      = aws_vpc.ACHISTAR_VPC.id

  # Inbound rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule to allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create public subnet route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ACHISTAR_VPC.id
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.ACHISTAR_public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create private subnet route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.ACHISTAR_VPC.id
}

# Associate private subnet with private route table
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.ACHISTAR_private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create route in private route table for NAT gateway
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
}

# Create route in public route table for internet gateway
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Create EC2 instances in the public subnet
resource "aws_instance" "public_instance" {
  count         = 4
  ami           = "ami-0261755bbcb8c4a84"  # Replace with the desired AMI ID
  instance_type = "t2.micro"
  key_name   = "star_kp"
  subnet_id     = aws_subnet.ACHISTAR_public_subnet.id
  vpc_security_group_ids = [aws_security_group.ACHISTAR_public_sg.id]
  depends_on = [aws_subnet.ACHISTAR_public_subnet,aws_security_group.ACHISTAR_public_sg]

}

# Create EC2 instance in the private subnet
resource "aws_instance" "private_instance" {
  count         = 1
  ami           = "ami-0261755bbcb8c4a84"  # Replace with the desired AMI ID
  instance_type = "t2.micro"
  key_name   = "star_kp"
  subnet_id     = aws_subnet.ACHISTAR_private_subnet.id
  vpc_security_group_ids = [aws_security_group.ACHISTAR_private_sg.id]
  depends_on = [aws_subnet.ACHISTAR_private_subnet,aws_security_group.ACHISTAR_private_sg]

}
