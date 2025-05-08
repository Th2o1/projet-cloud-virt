job "worker" {
  datacenters = ["perle"]
  type = "service"

  group "worker" {
    count = 3

    task "worker" {
      driver = "docker"

      config {
        image = "th2oo/image-worker:latest"
      }

      env {
        CELERY_BROKER_URL="amqp://perle:BR2oxgBERD4CJgYWiSGP@queue.internal.100do.se:5672/perle"
				S3_ENDPOINT_URL="https://s3.100do.se/"
				AWS_ACCESS_KEY_ID="perle"
				AWS_SECRET_ACCESS_KEY="pq3PAmSF128Q7q8H7pON"
				S3_BUCKET_NAME="perle"
      }

      resources {
        cpu    = 512      # MHz
        memory = 300      # MiB
      }
    }
  }
}