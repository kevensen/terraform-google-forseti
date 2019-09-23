/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//*****************************************
//  Setup Google providers
//*****************************************

provider "google" {
  version = "~> 2.11.0"
}

provider "google-beta" {
  version = "~> 2.12.0"
}

locals {
  k8s_forseti_namespace = "${var.k8s_forseti_namespace}-${module.forseti.suffix}"
  identity_namespace    = "${var.project_id}.svc.id.goog"
}

//*****************************************
//  Setup the Kubernetes Provider
//*****************************************

data "google_client_config" "default" {}

provider "kubernetes" {
  alias                  = "forseti"
  load_config_file       = false
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = "${base64decode(module.gke.ca_certificate)}"
}

//*****************************************
//  Setup Helm Provider
//*****************************************

provider "helm" {
  alias           = "forseti"
  service_account = var.k8s_tiller_sa_name
  namespace       = local.k8s_forseti_namespace
  kubernetes {
    load_config_file       = false
    host                   = "https://${module.gke.endpoint}"
    token                  = "${data.google_client_config.default.access_token}"
    cluster_ca_certificate = "${base64decode(module.gke.ca_certificate)}"
  }
  debug                           = true
  automount_service_account_token = true
  install_tiller                  = true
}

//*****************************************
//  Setup Network
//*****************************************

module "vpc" {
  source                  = "terraform-google-modules/network/google"
  version                 = "1.1.0"
  project_id              = "${var.project_id}"
  network_name            = "${var.network}"
  routing_mode            = "GLOBAL"
  description             = "${var.network_description}"
  auto_create_subnetworks = "${var.auto_create_subnetworks}"

  subnets = [{
    subnet_name   = "${var.subnetwork}"
    subnet_ip     = "${var.gke_node_ip_range}"
    subnet_region = "${var.region}"
  }, ]

  secondary_ranges = {
    "${var.subnetwork}" = [
      {
        range_name    = "gke-pod-ip-range"
        ip_cidr_range = "${var.gke_pod_ip_range}"
      },
      {
        range_name    = "gke-service-ip-range"
        ip_cidr_range = "${var.gke_service_ip_range}"
      },
    ]
  }
}

//*****************************************
//  Setup GKE Cluster
//*****************************************

module "gke" {
  // source                   = "terraform-google-modules/kubernetes-engine/google"
  // version                  = "4.1.0"
  source                   = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/beta-public-cluster/"
  project_id               = "${var.project_id}"
  name                     = "${var.gke_cluster_name}"
  regional                 = false
  region                   = "${var.region}"
  zones                    = "${var.zones}"
  network                  = "${module.vpc.network_name}"
  subnetwork               = "${module.vpc.subnets_names[0]}"
  ip_range_pods            = "gke-pod-ip-range"
  ip_range_services        = "gke-service-ip-range"
  service_account          = "${var.gke_service_account}"
  network_policy           = true
  remove_default_node_pool = true
  identity_namespace       = local.identity_namespace
  node_metadata            = "GKE_METADATA_SERVER"

  node_pools = [{
    name               = "default-node-pool"
    machine_type       = "n1-standard-2"
    min_count          = 1
    max_count          = 1
    disk_size_gb       = 100
    disk_type          = "pd-standard"
    image_type         = "COS"
    auto_repair        = true
    auto_upgrade       = true
    preemptible        = false
    initial_node_count = 1
  }, ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

//*****************************************
//  Deploy Forseti on GKE
//*****************************************

module "forseti" {
  providers = {
    kubernetes = "kubernetes.forseti"
    helm       = "helm.forseti"
  }
  source             = "../../modules/on_gke"
  domain             = var.domain
  gsuite_admin_email = var.gsuite_admin_email
  project_id         = var.project_id
  org_id             = var.org_id

  storage_bucket_location = var.region
  bucket_cai_location     = var.region

  cloudsql_region = var.region

  helm_repository_url              = var.helm_repository_url
  config_validator_enabled         = var.config_validator_enabled
  git_sync_private_key_file        = var.git_sync_private_key_file
  gke_service_account              = module.gke.service_account
  k8s_forseti_namespace            = local.k8s_forseti_namespace
  load_balancer                    = var.load_balancer
  network_policy                   = module.gke.network_policy_enabled
  policy_library_repository_url    = var.policy_library_repository_url
  policy_library_repository_branch = var.policy_library_repository_branch
  forseti_email_sender             = var.forseti_email_sender
  forseti_email_recipient          = var.forseti_email_recipient
  sendgrid_api_key                 = var.sendgrid_api_key

  subnetwork                  = module.vpc.subnets_names[0]
  network_project             = var.project_id
  network_policy_ingress_cidr = module.vpc.subnets_ips[0]

  server_log_level = var.server_log_level
}
