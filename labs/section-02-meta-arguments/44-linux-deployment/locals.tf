# Lab 44 — deploy the restructured VM (lab 43) end to end with public IP + NSG.
# locals: the SSH key read from disk (ternary fallback) and the RG name.
locals {
  ssh_pubkey = fileexists("id_rsa.pub") ? file("id_rsa.pub") : "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzc5yjPpF02BZc/k9D6S2pkKmBfZFksOBDaD3W/DvbJmN557CipWKC3nqw4NpRp8U25xD0T4RGOXSSRzneDT3zwZxEhqt4y3A9r39KwOCz0VKOalTZ5X1HPV9tgh+ljBjDluu812+UG0mAeYZ3HMWFuqypNFGRL5vxOEPSkmCYbxxOH/5hpIX3b4mBlq1EeSY+k1L3NQqiQ6byNU2xP69gLiT0EUbyrb4g4IuK/zGj7X+upJaVF7Dfgpqe8O70dRzgiIPAuTsqkkEFt+cAawUOMaNfDOhnjQktZBlMYpgWPhU7Dcn+ICyAoruzmXLH79PhttaCAyF0xNtUz7xXAn9v terraform-lab-placeholder"
  rg         = "rg-linux-deploy"
}
