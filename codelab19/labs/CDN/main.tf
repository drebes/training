provider "google" {}

provider "google-beta" {}

locals {
  prefix       = ""
  image        = "debian-cloud/debian-9"
  machine_type = "n1-standard-1"
}

#============================================
# VPC Demo Configuration
#============================================

# VPC Demo Network

locals {
  vpc_demo_subnet_cdn = "${local.prefix}vpc-demo-subnet-cdn"
}

module "vpc_demo" {
  source  = "terraform-google-modules/network/google"
  version = "0.6.0"

  project_id   = "${var.project_id}"
  network_name = "${local.prefix}vpc-demo"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${local.vpc_demo_subnet_cdn}"
      subnet_ip             = "10.1.33.0/24"
      subnet_region         = "asia-east1"
      subnet_private_access = false
      subnet_flow_logs      = false
    },
  ]

  secondary_ranges = {
    "${local.vpc_demo_subnet_cdn}" = []
  }
}

resource "google_compute_firewall" "vpc_demo_allow_internal" {
  provider = "google-beta"
  name     = "${local.prefix}vpc-demo-allow-internal"
  network  = "${module.vpc_demo.network_self_link}"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.1.0.0/16"]
}

resource "google_compute_firewall" "vpc_demo_allow_ssh_http_s_icmp" {
  provider = "google-beta"
  name     = "${local.prefix}vpc-demo-allow-ssh-http-s-icmp"
  network  = "${module.vpc_demo.network_self_link}"

  allow {
    protocol = "tcp"
    ports    = [22, 80, 443]
  }

  allow {
    protocol = "icmp"
  }
}

module "http_lb" {
  source                  = "../../modules/http_lb"
  project_id              = "${var.project_id}"
  prefix                  = "${local.prefix}"
  instance_template_name  = "cdn-www-template"
  region                  = "asia-east1"
  machine_type            = "${local.machine_type}"
  image                   = "${local.image}"
  subnetwork_project      = "${var.project_id}"
  subnetwork              = "${module.vpc_demo.subnets_self_links[0]}"
  metadata_startup_script = "${file("scripts/startup.sh")}"
  instance_group_name     = "cdn-mig"
  health_check_name       = "http-basic-check"
  backend_service_name    = "cdn-backend-service"
  url_map_name            = "cdn-map"
  target_proxy_name       = "cdn-proxy"
  forwarding_rule_name    = "cdn-rule"

  named_port = {
    name = "http"
    port = "80"
  }
}

# cdn ip output

output "cdn-ip" {
  value = "${module.http_lb.cdn_ip}"
}