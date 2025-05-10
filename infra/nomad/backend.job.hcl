job "backend" {
  datacenters = ["perle"]
  type = "service"

  group "backend" {
    count = 3  # Run on all three nodes

    network {
      mode = "host"  # Use host networking
    }

    service {
      name = "backend"
      port = 8080  # Specify port directly for host networking
      tags = ["urlprefix-/api"]
      provider = "consul"
      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "backend" {
      driver = "docker"

      config {
        image = "th2oo/image-backend:latest"
        network_mode = "host"  # Optional redundancy
      }

      env {
        CELERY_BROKER_URL        = "amqp://perle:BR2oxgBERD4CJgYWiSGP@queue.internal.100do.se:5672/perle"
        S3_ENDPOINT_URL          = "https://s3.100do.se/"
        AWS_ACCESS_KEY_ID        = "perle"
        AWS_SECRET_ACCESS_KEY    = "pq3PAmSF128Q7q8H7pON"
        S3_BUCKET_NAME           = "perle"
      }

      resources {
        cpu    = 150  # MHz
        memory = 400  # MiB
      }
    }
  }
}
