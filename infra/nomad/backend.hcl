job "backend" {
  datacenters = ["perle"]
  type = "service"

  group "backend" {
    count = 3

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    service {
      name = "backend"
      port = "http"
    }

    task "backend" {
      driver = "docker"

      config {
        image = "th2oo/image-backend:latest"
        ports = ["http"]
      }

      env {
        CELERY_BROKER_URL="amqp://perle:BR2oxgBERD4CJgYWiSGP@queue.internal.100do.se:5672/perle"
				S3_ENDPOINT_URL="https://s3.100do.se/"
				AWS_ACCESS_KEY_ID="perle"
				AWS_SECRET_ACCESS_KEY="pq3PAmSF128Q7q8H7pON"
				S3_BUCKET_NAME="perle"
      }

      resources {
        cpu    = 150    # MHz
        memory = 400    # MiB
      }
    }
  }
}