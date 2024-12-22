# Variables
variable "snapcast_namespace" {
  default = "snapserver"
}

variable "snapserver_image" {
  default = "dockyard.iszland.com/snapserver:tls-2"
}

variable "snapserver_host" {
  default = "snapserver.iszland.com"
}

variable "cert_manager_cloudflare_dns_secret_name_prefix" {
  default = "iszland-com"
}

variable "use_production_issuer" {
  description = "Use production issuer if true, otherwise use the staging issuer."
  type        = bool
  default     = false
}

variable "load_balancer_ip" {
  default = "10.10.10.31"
}

variable "CERT_MANAGER_CLOUDFLARE_DNS_ZONE" {
  default = "iszland.com"
}

variable "DOCKER_REGISTRY_SERVER" {
  description = "The Docker registry server URL"
  sensitive   = true
}

variable "DOCKER_REGISTRY_USERNAME" {
  description = "The Docker registry username"
  sensitive   = true
}

variable "DOCKER_REGISTRY_PASSWORD" {
  description = "The Docker registry password"
  sensitive   = true
}

variable "DOCKER_REGISTRY_EMAIL" {
  description = "The Docker registry email address"
  sensitive   = true
}

variable "SPOTIFY_USER_0_NAME" {
  description = "A spotify name to register streaming access to Spotify"
  sensitive   = true
}

variable "spotify_users" {
  description = "List of Spotify users with their auth tokens"
  type        = list(object({
    name          = string
    username          = string
    auth_token        = string
  }))
  default = [
    {
      name       = ""
      username   = ""
      auth_token = ""
    }
  ]
}

