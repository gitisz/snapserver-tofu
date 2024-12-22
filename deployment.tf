# Namespace for Snapcast deployment
resource "kubernetes_manifest" "snapcast_namespace" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = var.snapcast_namespace
    }
  }
}

# Docker Registry secret
resource "kubernetes_manifest" "docker_registry" {
  depends_on = [kubernetes_manifest.snapcast_namespace]

  manifest = yamldecode(templatefile("./deployments/credentials/docker-registry-secret.yaml", {
    base64_encoded_docker_config = base64encode(
      templatefile("./deployments/credentials/docker-registry/credentials.json", {
        docker_registry_server          = var.DOCKER_REGISTRY_SERVER,
        docker_registry_username        = var.DOCKER_REGISTRY_USERNAME,
        docker_registry_password        = var.DOCKER_REGISTRY_PASSWORD,
        docker_registry_email           = var.DOCKER_REGISTRY_EMAIL,
        base64_encoded_username_password = base64encode("${var.DOCKER_REGISTRY_USERNAME}:${var.DOCKER_REGISTRY_PASSWORD}")
      })
    )
  }))
}

# Spotify Secrets
resource "kubernetes_manifest" "spotify_users" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  count = length(var.spotify_users)
  manifest = yamldecode(templatefile("./deployments/credentials/spotify-secret.yaml", {
    spotify_name                    = var.spotify_users[count.index].name,
    base64_encoded_spotify_credentials = base64encode(
      templatefile("./deployments/credentials/spotify/credentials.json", {
        spotify_username            = var.spotify_users[count.index].username,
        spotify_auth_token          = var.spotify_users[count.index].auth_token
      })
    )
  }))
}


locals {
  snapserver_config_entries = [for user in var.spotify_users : "source = spotify:///librespot?name=${upper(user.name)}&devicename=${user.username}&bitrate=320&volume=100&killall=false&cache=/snapserver/${user.name}"]
}

resource "kubernetes_manifest" "snapserver_config" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  manifest = yamldecode(templatefile("./deployments/snapserver-config-map.yaml", {
    snapserver_config_entries = local.snapserver_config_entries,
    snapserver_host = var.snapserver_host
  }))
}

resource "kubernetes_manifest" "snapserver_persistent_volume_claim_logs" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  manifest = yamldecode(templatefile("./deployments/snapserver-pvc-logs.yaml", {
  }))
}

resource "kubernetes_manifest" "snapserver_persistent_volume_claim_fifo" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  manifest = yamldecode(templatefile("./deployments/snapserver-pvc-fifo.yaml", {
  }))
}

resource "kubernetes_manifest" "snapserver_persistent_volume_claim_users" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  count = length(var.spotify_users)
  manifest = yamldecode(templatefile("./deployments/snapserver-pvc-user.yaml", {
    spotify_user = var.spotify_users[count.index]
  }))
}

resource "kubernetes_manifest" "snapserver_deployment" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  manifest = yamldecode(templatefile("./deployments/snapserver-deployment.yaml", {
    snapserver_image = var.snapserver_image,
    spotify_users = var.spotify_users,
    additional_ports = range(4953, 5155)
  }))
}

resource "kubernetes_manifest" "snapserver_service" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  manifest = yamldecode(templatefile("./deployments/snapserver-service.yaml", {
    load_balancer_ip = var.load_balancer_ip,
    additional_ports = range(4953, 5155)
  }))
}


locals {
  cert_manager_issuer_environment = var.use_production_issuer ? "production" : "staging"
}

resource "kubernetes_manifest" "snapserver_ingress_web" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  manifest = yamldecode(templatefile("./deployments/snapserver-ingress-web.yaml", {
    snapserver_host = var.snapserver_host,
    cert_manager_cloudflare_dns_secret_name_prefix = var.cert_manager_cloudflare_dns_secret_name_prefix,
    cert_manager_issuer_environment = local.cert_manager_issuer_environment
  }))
}

# resource "kubernetes_manifest" "snapserver_ingress_1704" {
#   depends_on = [kubernetes_manifest.snapcast_namespace]
#   manifest = yamldecode(templatefile("./deployments/snapserver-ingress-1704.yaml", {
#     snapserver_host = var.snapserver_host,
#   }))
# }

# resource "kubernetes_manifest" "snapserver_ingress_1705" {
#   depends_on = [kubernetes_manifest.snapcast_namespace]
#   manifest = yamldecode(templatefile("./deployments/snapserver-ingress-1705.yaml", {
#     snapserver_host = var.snapserver_host,
#   }))
# }

resource "kubernetes_manifest" "snapserver_certificate" {
  depends_on = [kubernetes_manifest.snapcast_namespace]
  manifest = yamldecode(templatefile("./deployments/certificates/${local.cert_manager_issuer_environment}/snapserver-certificate.yaml", {
    cert_manager_cloudflare_dns_secret_name_prefix = var.cert_manager_cloudflare_dns_secret_name_prefix,
    cert_manager_cloudflare_dns_zone = var.CERT_MANAGER_CLOUDFLARE_DNS_ZONE
  }))
}

