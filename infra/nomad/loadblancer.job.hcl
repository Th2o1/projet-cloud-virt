job "loadbalancer" {
  type = "system"

  group "loadbalancer" {
    count = 1

    service {
      name     = "haproxy"
      provider = "consul"
    }

    task "proxy" {
      driver = "docker"

      config {
        image         = "haproxy:2.5"
        network_mode  = "host"

        mount {
          type   = "bind"
          source = "local/config"
          target = "/usr/local/etc/haproxy/haproxy.cfg"
        }
      }

      template {
        destination   = "local/config/haproxy.cfg"
        change_mode   = "signal"
        change_signal = "SIGHUP"

        data = <<EOF
global
  daemon
  maxconn 1024

defaults
  mode http
  balance roundrobin
  timeout client 60s
  timeout connect 60s
  timeout server 60s

frontend stats
  bind *:8082
  stats enable
  stats uri /stats
  stats refresh 10s
  stats admin if TRUE

frontend http
  bind *:8081
  acl api_path path_beg /image
  use_backend back if api_path
  default_backend front

backend back
  balance roundrobin
  server-template back 1-10 _backend._tcp.service.consul resolvers consul check

backend front
  balance roundrobin
  server-template front 1-10 _frontend._tcp.service.consul resolvers consul check

resolvers consul
  parse-resolv-conf
  accepted_payload_size 8192
  hold valid 5s
EOF
      }
    }
  }
}
