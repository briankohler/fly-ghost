terraform {
  backend "s3" {
    bucket = "bk-terraform-state"
    key = "ghost-kohler-cloud"
    region = "us-east-1"
    skip_credentials_validation = true
    endpoint = "s3.wasabisys.com"
  }
  required_providers {
    fly = {
      source  = "fly-apps/fly"
      version = "0.0.20"
    }
    wasabi = {
      source  = "terrabitz/wasabi"
      version = "4.1.3"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

provider "wasabi" {
  region  = "us-east-1"
  profile = "wasabi"
}

provider "fly" {
  internaltunnelorg    = var.org
  internaltunnelregion = var.region
  useinternaltunnel    = true
}

data "digitalocean_domain" "domain" {
  name = join(".", slice(split(".", var.domain_name), 1, 3))
}

resource "digitalocean_record" "ghost" {
  domain = data.digitalocean_domain.domain.id
  type   = "CNAME"
  name   = split(".", var.domain_name)[0]
  value  = "${var.app_name}.fly.dev."
}

resource "wasabi_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "wasabi_user" "user" {
  name = "ghost_backup"
}

data "template_file" "userpolicy" {
  template = file("${path.module}/templates/user_policy.json.tmpl")
  vars = {
    bucket = wasabi_bucket.bucket.id
  }
}

resource "wasabi_policy" "userpolicy" {
  policy = data.template_file.userpolicy.rendered
  name   = "ghost-policy"
}

resource "wasabi_policy_attachment" "policyattach" {
  name       = "${wasabi_user.user.id}-attachment"
  policy_arn = wasabi_policy.userpolicy.arn
  users      = [wasabi_user.user.id]
}

resource "wasabi_access_key" "accesskey" {
  user = wasabi_user.user.id
}

data "template_file" "flytoml" {
  template = file("${path.module}/templates/fly.toml.tmpl")

  vars = {
    bucket_name    = var.bucket_name
    bucket_region  = var.bucket_region
    app_name       = var.app_name
    domain         = var.domain_name
    primary_region = var.region
    memory         = var.memory
    access_key     = wasabi_access_key.accesskey.id
  }
}

resource "local_file" "flytoml" {
  content  = data.template_file.flytoml.rendered
  filename = "${path.module}/fly.toml"
}

resource "fly_app" "ghost" {
  name = var.app_name
  org  = var.org
}

data "template_file" "litestreamyml" {
  template = file("${path.module}/templates/litestream.yml.tmpl")
  vars = {
    retention     = var.retention
    bucket        = wasabi_bucket.bucket.id
    bucket_region = var.bucket_region
  }
}

resource "local_file" "litestreamyml" {
  content  = data.template_file.litestreamyml.rendered
  filename = "${path.module}/litestream.yml"
}

resource "fly_ip" "ip4" {
  app  = fly_app.ghost.name
  type = "v4"
}

resource "fly_ip" "ip6" {
  app  = fly_app.ghost.name
  type = "v6"
}

resource "fly_cert" "ghost" {
  app        = fly_app.ghost.name
  hostname   = var.domain_name
  depends_on = [fly_ip.ip4, fly_ip.ip6]
}

resource "fly_volume" "volume" {
  name   = "data"
  app    = fly_app.ghost.name
  size   = var.volume_size
  region = var.region
}


output "accesskeysecret" {
  value     = wasabi_access_key.accesskey.secret
  sensitive = true
}

output "memory" {
  value = var.memory
}
