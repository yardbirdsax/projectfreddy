variable "keyName" {
  type = "string"
}

data aws_ami "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

# resource aws_instance "es-lab" {
  
#   ami = "${data.aws_ami.ubuntu.id}"
#   instance_type = "t3.xlarge"
#   tags = {
#     Name = "${local.tagName}-${count.index}"
#   }
#   count = 3
#   subnet_id = var.subnetId
#   vpc_security_group_ids = [aws_security_group.es-labSG.id]
#   key_name = var.keyName
#   user_data = <<EOF
# #cloud-config
# ---
# hostname: "${local.tagName}-${count.index}"
# EOF
# }

# resource aws_eip "es-labElasticIp" {
#   vpc = true
#   count = 3
#   instance = aws_instance.es-lab[count.index].id
# }