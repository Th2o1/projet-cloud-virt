job "frontend" {
  datacenters = ["perle"]
  type = "service"

  group "frontend" {
    count = 1

    network {
      port "http" {
        static = 8081  # Port requis par le proxy
        to = 3000     # Port du conteneur (serve écoute sur 3000)
      }
    }

    service {
      name = "frontend"
      port = "http"
      tags = ["frontend"]
      provider = "consul"
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "th2oo/image-frontend:latest"
        ports = ["http"]
      }
    }
  }
}