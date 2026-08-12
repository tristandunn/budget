output "ipv4_address" {
  type        = string
  value       = digitalocean_droplet.web.ipv4_address
  description = "The public IP address of the website server."
}
