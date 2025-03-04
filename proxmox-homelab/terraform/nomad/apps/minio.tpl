job "minio" {
  datacenters = ${datacenters}

  group "minio" {
    count = 1

    network {
      mode = "bridge"
      port "api" {
        to = "9000"
      }
      port "http" {
        to = "9001"
      }
    }

    service {
      provider = "consul"
      name     = "$${JOB}-api"
      port     = "api"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.minio-proxy.entrypoints=https",
        "traefik.http.routers.minio-proxy.tls=true",
        "traefik.http.routers.minio-proxy.rule=Host(`${minio_subdomain}.${domain}`)",
      ]

      check {
        type     = "http"
        path     = "/minio/health/live"
        port     = "api"
        interval = "30s"
        timeout  = "5s"

        success_before_passing   = "3"
        failures_before_critical = "3"
      }
    }

    service {
      provider = "consul"
      name     = "$${JOB}-console"
      port     = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.minio-console.entrypoints=https",
        "traefik.http.routers.minio-console.tls=true",
        "traefik.http.routers.minio-console.rule=Host(`${minio_console_subdomain}.${domain}`)",
      ]

      check {
        type     = "http"
        path     = "/"
        port     = "http"
        interval = "30s"
        timeout  = "5s"

        success_before_passing   = "3"
        failures_before_critical = "3"
      }
    }

    task "minio" {
      driver = "docker"
      user   = "1000"

      config {
        image = "quay.io/minio/minio:${minio_image_version}"
        ports = ["api", "http"]
        args  = ["server", "/data", "--console-address", ":9001"]

        volumes = [
          "${minio_volumes_data}:/data",
        ]

        labels = {
          "diun.enable"     = "true"
          "diun.watch_repo" = "true"
          "diun.max_tags"   = 3
        }
      }

      vault {
        policies = ["nomad_minio"]
      }

      env {
        MINIO_BROWSER_LOGIN_ANIMATION = "off"
        MINIO_BROWSER_REDIRECT_URL    = "https://${minio_console_subdomain}.${domain}"

        # Docker cannot resolve this address if given
        # MINIO_SERVER_URL              = "https://${minio_subdomain}.${domain}"
      }

      template {
        data        = <<EOF
{{ with secret "kvv2/data/prod/nomad/minio" }}
MINIO_ROOT_USER="{{ .Data.data.username }}"
MINIO_ROOT_PASSWORD="{{ .Data.data.password }}"
{{ end }}
EOF
        destination = "secrets/auth.env"
        env         = true
      }

      resources {
        cpu    = 200
        memory = 400
      }
    }
  }
}
