job "countdash" {
  datacenters = ${datacenters}

  group "api" {
    count = ${countdash_count}

    network {
      mode = "bridge"
    }

    service {
      name = "count-api"
      port = "9001"

      connect {
        sidecar_service {}
      }
    }

    task "web" {
      driver = "docker"
      config {
        image = "hashicorpnomad/counter-api:v1"
      }
    }
  }

  group "dashboard" {
    network {
      mode = "bridge"
      port "http" {
        static = ${countdash_port}
        to     = 9002
      }
    }

    service {
      name = "count-dashboard"
      port = "9002"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port  = 8080
            }
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"
      env {
        COUNTING_SERVICE_URL = "http://$${NOMAD_UPSTREAM_ADDR_count_api}"
      }
      config {
        image = "hashicorpnomad/counter-dashboard:v1"
      }
    }
  }
}
