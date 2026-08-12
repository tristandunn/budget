terraform {
  required_version = "~> 1.15.0"

  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "= 2.4.0"
    }

    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "= 2.99.1"
    }
  }
}
