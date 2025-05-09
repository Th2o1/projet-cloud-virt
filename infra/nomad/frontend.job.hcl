job "frontend" {
  datacenters = ["perle"]
  type = "service"

  group "frontend" {
    count = 3 

    network {
      mode = "host"
    }

    service {
      name = "frontend"
      port = 8081
      tags = ["frontend", "urlprefix-/"]
      provider = "consul"
      check { # Health check
          type     = "http"
          path     = "/"  
          interval = "10s"
          timeout  = "2s"
        }
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "th2oo/image-frontend:latest"
        network_mode = "host"
      }
    }
  }
}
