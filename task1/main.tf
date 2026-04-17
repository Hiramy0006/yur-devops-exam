terraform {
  required_providers {
    digitalocean = { source = "digitalocean/digitalocean", version = "~> 2.0" }
  }
  backend "s3" {
    endpoints                   = { s3 = "https://fra1.digitaloceanspaces.com" }
    bucket                      = "yur-tfstate"
    key                         = "exam/terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}

variable "do_token" {}
variable "spaces_access_id" {}
variable "spaces_secret_key" {}

provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

# Створюємо VPC з унікальним іменем для екзамену
resource "digitalocean_vpc" "exam_vpc" {
  name     = "yur-exam-vpc-unique"
  region   = "fra1"
  ip_range = "10.11.12.0/24" # Змінив підмережу, щоб не перетиналася
}

# Firewall з унікальним іменем
resource "digitalocean_firewall" "exam_fw" {
  name = "yur-exam-firewall-unique"

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8000-8003"
    source_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# Створюємо Droplet
resource "digitalocean_droplet" "exam_node" {
  name     = "yur-exam-node"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-24-04-x64"
  region   = "fra1"
  vpc_uuid = digitalocean_vpc.exam_vpc.id
  # Якщо у тебе в DO вже доданий ключ, Terraform його підтягне, якщо ми вкажемо відбиток (fingerprint)
  # Але для спрощення на екзамені просто створимо дроплет у цій VPC
}

# Створюємо окремий бакет для контенту (Завдання 1)
resource "digitalocean_spaces_bucket" "exam_bucket" {
  name   = "yur-exam-content-bucket"
  region = "fra1"
}

output "droplet_ip" {
  value = digitalocean_droplet.exam_node.ipv4_address
}
