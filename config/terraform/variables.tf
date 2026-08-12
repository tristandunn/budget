variable "droplet_name" {
  type    = string
  default = "budget"
}

variable "droplet_image" {
  type    = string
  default = "ubuntu-26-04-x64"
}

variable "droplet_region" {
  type    = string
  default = "nyc3"
}

variable "droplet_size" {
  type    = string
  default = "s-1vcpu-2gb"
}
