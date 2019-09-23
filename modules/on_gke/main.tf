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

resource "random_id" "random_hash_suffix" {
  byte_length = 4
}

resource "null_resource" "org_id_and_folder_id_are_both_empty" {
  count = length(var.composite_root_resources) == 0 && var.org_id == "" && var.folder_id == "" ? 1 : 0

  provisioner "local-exec" {
    command     = "echo 'composite_root_resources=${var.composite_root_resources} org_id=${var.org_id} folder_id=${var.org_id}' >&2; false"
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "email_without_sendgrid_api_key" {
  count = var.inventory_email_summary_enabled == "true" && var.sendgrid_api_key == "" ? 1 : 0

  provisioner "local-exec" {
    command     = "echo 'inventory_email_summary_enabled=${var.inventory_email_summary_enabled} sendgrid_api_key=${var.sendgrid_api_key}' >&2; false"
    interpreter = ["bash", "-c"]
  }
}

#--------#
# Locals #
#--------#
locals {
  random_hash     = var.resource_name_suffix == null ? random_id.random_hash_suffix.hex : var.resource_name_suffix
  network_project = var.network_project != "" ? var.network_project : var.project_id

  identity_namespace = "${var.project_id}.svc.id.goog"

  services_list = [
    "admin.googleapis.com",
    "appengine.googleapis.com",
    "bigquery-json.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudtrace.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "servicemanagement.googleapis.com",
    "logging.googleapis.com",
    "cloudasset.googleapis.com",
    "storage-api.googleapis.com",
    "groupssettings.googleapis.com",
  ]

  cscc_violations_enabled_services_list = [
    "securitycenter.googleapis.com",
  ]
}

#-------------------#
# Activate services #
#-------------------#
resource "google_project_service" "main" {
  count              = length(local.services_list)
  project            = var.project_id
  service            = local.services_list[count.index]
  disable_on_destroy = "false"
}

resource "google_project_service" "cscc_violations" {
  count              = var.cscc_violations_enabled ? length(local.cscc_violations_enabled_services_list) : 0
  project            = var.project_id
  service            = local.cscc_violations_enabled_services_list[count.index]
  disable_on_destroy = "false"
}

module "cloudsql" {
  source             = "../cloudsql"
  cloudsql_disk_size = var.cloudsql_disk_size
  cloudsql_private   = var.cloudsql_private
  cloudsql_region    = var.cloudsql_region
  cloudsql_type      = var.cloudsql_type
  network_project    = var.network_project
  project_id         = var.project_id
  services           = google_project_service.main.*.service
  suffix             = local.random_hash
}

module "server_iam" {
  source                  = "../server_iam"
  cscc_violations_enabled = var.cscc_violations_enabled
  enable_write            = var.enable_write
  project_id              = var.project_id
  org_id                  = var.org_id
  suffix                  = local.random_hash
}

module "server_gcs" {
  source                   = "../server_gcs"
  project_id               = var.project_id
  bucket_cai_location      = var.bucket_cai_location
  bucket_cai_lifecycle_age = var.bucket_cai_lifecycle_age
  enable_cai_bucket        = var.enable_cai_bucket
  storage_bucket_location  = var.storage_bucket_location
  services                 = google_project_service.main.*.service
  suffix                   = local.random_hash
}

module "server_rules" {
  source               = "../rules"
  server_gcs_module    = module.server_gcs
  org_id               = var.org_id
  domain               = var.domain
  manage_rules_enabled = var.manage_rules_enabled
}

module "server_config" {
  source                                              = "../server_config"
  composite_root_resources                            = var.composite_root_resources
  server_gcs_module                                   = module.server_gcs
  forseti_email_recipient                             = var.forseti_email_recipient
  forseti_email_sender                                = var.forseti_email_sender
  sendgrid_api_key                                    = var.sendgrid_api_key
  org_id                                              = var.org_id
  folder_id                                           = var.folder_id
  domain                                              = var.domain
  gsuite_admin_email                                  = var.gsuite_admin_email
  storage_disable_polling                             = var.storage_disable_polling
  sqladmin_period                                     = var.sqladmin_period
  sqladmin_max_calls                                  = var.sqladmin_max_calls
  sqladmin_disable_polling                            = var.sqladmin_disable_polling
  servicemanagement_period                            = var.servicemanagement_period
  servicemanagement_max_calls                         = var.servicemanagement_max_calls
  servicemanagement_disable_polling                   = var.servicemanagement_disable_polling
  securitycenter_period                               = var.securitycenter_period
  securitycenter_max_calls                            = var.securitycenter_max_calls
  securitycenter_disable_polling                      = var.securitycenter_disable_polling
  logging_period                                      = var.logging_period
  logging_max_calls                                   = var.logging_max_calls
  logging_disable_polling                             = var.logging_disable_polling
  iam_period                                          = var.iam_period
  iam_max_calls                                       = var.iam_max_calls
  iam_disable_polling                                 = var.iam_disable_polling
  crm_period                                          = var.crm_period
  crm_max_calls                                       = var.crm_max_calls
  crm_disable_polling                                 = var.crm_disable_polling
  container_period                                    = var.container_period
  container_max_calls                                 = var.container_max_calls
  container_disable_polling                           = var.container_disable_polling
  compute_period                                      = var.compute_period
  compute_max_calls                                   = var.compute_max_calls
  compute_disable_polling                             = var.compute_disable_polling
  cloudbilling_period                                 = var.cloudbilling_period
  cloudbilling_max_calls                              = var.cloudbilling_max_calls
  cloudbilling_disable_polling                        = var.cloudbilling_disable_polling
  cloudasset_period                                   = var.cloudasset_period
  cloudasset_max_calls                                = var.cloudasset_max_calls
  cloudasset_disable_polling                          = var.cloudasset_disable_polling
  inventory_retention_days                            = var.inventory_retention_days
  cai_api_timeout                                     = var.cai_api_timeout
  bigquery_period                                     = var.bigquery_period
  bigquery_max_calls                                  = var.bigquery_max_calls
  bigquery_disable_polling                            = var.bigquery_disable_polling
  appengine_period                                    = var.appengine_period
  appengine_max_calls                                 = var.appengine_max_calls
  appengine_disable_polling                           = var.appengine_disable_polling
  admin_period                                        = var.admin_period
  admin_max_calls                                     = var.admin_max_calls
  admin_disable_polling                               = var.admin_disable_polling
  service_account_key_enabled                         = var.service_account_key_enabled
  resource_enabled                                    = var.resource_enabled
  log_sink_enabled                                    = var.log_sink_enabled
  location_enabled                                    = var.location_enabled
  lien_enabled                                        = var.lien_enabled
  ke_version_scanner_enabled                          = var.ke_version_scanner_enabled
  kms_scanner_enabled                                 = var.kms_scanner_enabled
  ke_scanner_enabled                                  = var.ke_scanner_enabled
  instance_network_interface_enabled                  = var.instance_network_interface_enabled
  iap_enabled                                         = var.iap_enabled
  iam_policy_enabled                                  = var.iam_policy_enabled
  group_enabled                                       = var.group_enabled
  forwarding_rule_enabled                             = var.forwarding_rule_enabled
  firewall_rule_enabled                               = var.firewall_rule_enabled
  enabled_apis_enabled                                = var.enabled_apis_enabled
  cloudsql_acl_enabled                                = var.cloudsql_acl_enabled
  config_validator_enabled                            = var.config_validator_enabled
  bucket_acl_enabled                                  = var.bucket_acl_enabled
  blacklist_enabled                                   = var.blacklist_enabled
  bigquery_enabled                                    = var.bigquery_enabled
  audit_logging_enabled                               = var.audit_logging_enabled
  service_account_key_violations_should_notify        = var.service_account_key_violations_should_notify
  resource_violations_should_notify                   = var.resource_violations_should_notify
  log_sink_violations_should_notify                   = var.log_sink_violations_should_notify
  location_violations_should_notify                   = var.location_violations_should_notify
  lien_violations_should_notify                       = var.lien_violations_should_notify
  ke_violations_should_notify                         = var.ke_violations_should_notify
  ke_version_violations_should_notify                 = var.ke_version_violations_should_notify
  kms_violations_should_notify                        = var.kms_violations_should_notify
  kms_violations_slack_webhook                        = var.kms_violations_slack_webhook
  inventory_gcs_summary_enabled                       = var.inventory_gcs_summary_enabled
  inventory_email_summary_enabled                     = var.inventory_email_summary_enabled
  instance_network_interface_violations_should_notify = var.instance_network_interface_violations_should_notify
  iap_violations_should_notify                        = var.iap_violations_should_notify
  iam_policy_violations_should_notify                 = var.iam_policy_violations_should_notify
  iam_policy_violations_slack_webhook                 = var.iam_policy_violations_slack_webhook
  groups_violations_should_notify                     = var.groups_violations_should_notify
  forwarding_rule_violations_should_notify            = var.forwarding_rule_violations_should_notify
  firewall_rule_violations_should_notify              = var.firewall_rule_violations_should_notify
  external_project_access_violations_should_notify    = var.external_project_access_violations_should_notify
  enabled_apis_violations_should_notify               = var.enabled_apis_violations_should_notify
  cloudsql_acl_violations_should_notify               = var.cloudsql_acl_violations_should_notify
  config_validator_violations_should_notify           = var.config_validator_violations_should_notify
  buckets_acl_violations_should_notify                = var.buckets_acl_violations_should_notify
  blacklist_violations_should_notify                  = var.blacklist_violations_should_notify
  bigquery_acl_violations_should_notify               = var.bigquery_acl_violations_should_notify
  audit_logging_violations_should_notify              = var.audit_logging_violations_should_notify
  excluded_resources                                  = var.excluded_resources
  violations_slack_webhook                            = var.violations_slack_webhook
  cscc_violations_enabled                             = var.cscc_violations_enabled
  cscc_source_id                                      = var.cscc_source_id

  groups_settings_max_calls                = var.groups_settings_max_calls
  groups_settings_period                   = var.groups_settings_period
  groups_settings_disable_polling          = var.groups_settings_disable_polling
  groups_settings_enabled                  = var.groups_settings_enabled
  groups_settings_violations_should_notify = var.groups_settings_violations_should_notify
}

module "client_iam" {
  source     = "../client_iam"
  project_id = var.project_id
  suffix     = local.random_hash
}

//*****************************************
//  Allow GKE Service Account to read GCS
//*****************************************

resource "google_project_iam_member" "cluster_service_account-storage_reader" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${var.gke_service_account}"
}


//*****************************************
//  Setup the Forseti server and client
//  service accounts for workload identity
//*****************************************

resource "google_service_account_iam_binding" "forseti_server_service_account" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.server_iam.forseti-server-service-account}"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${local.identity_namespace}[${var.k8s_forseti_namespace}/forseti-server]"
  ]
}

resource "google_service_account_iam_binding" "forseti_client_service_account" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.client_iam.forseti-client-service-account}"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${local.identity_namespace}[${var.k8s_forseti_namespace}/forseti-client]"
  ]
}

//*****************************************
//  Obtain Forseti Server Configiration
//*****************************************

data "google_storage_object_signed_url" "file_url" {
  bucket     = module.server_gcs.forseti-server-storage-bucket
  path       = "configs/forseti_conf_server.yaml"
  depends_on = [module.server_config.forseti-server-config]
}

data "http" "server_config_contents" {
  url        = data.google_storage_object_signed_url.file_url.signed_url
  depends_on = ["data.google_storage_object_signed_url.file_url"]
}

//*****************************************
//  Create Tiller Kubernetes Service Account
//*****************************************

resource "kubernetes_namespace" "forseti" {
  metadata {
    name = var.k8s_forseti_namespace
  }
}

//*****************************************
//  Create Tiller Kubernetes Service Account
//*****************************************

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = var.k8s_tiller_sa_name
    namespace = var.k8s_forseti_namespace
  }
  depends_on = [
    "kubernetes_namespace.forseti"
  ]

}

//*****************************************
//  Create Tiller RBAC
//*****************************************

resource "kubernetes_role" "tiller" {
  metadata {
    name      = "tiller-manager"
    namespace = var.k8s_forseti_namespace
  }

  rule {
    api_groups = ["", "extensions", "apps", "batch/v1beta1", "batch", "networking.k8s.io", "rbac.authorization.k8s.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "tiller" {
  metadata {
    name      = "tiller-binding"
    namespace = var.k8s_forseti_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.tiller.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller.metadata.0.name
    namespace = var.k8s_forseti_namespace
  }
}

data "local_file" "git_sync_private_key_file" {
  filename = var.git_sync_private_key_file
}

//*****************************************
//  Deploy Forseti on GKE via Helm
//*****************************************

resource "helm_release" "forseti_security" {
  name          = "forseti"
  namespace     = var.k8s_forseti_namespace
  repository    = var.helm_repository_url
  chart         = "forseti-security"
  recreate_pods = var.recreate_pods
  depends_on = ["kubernetes_role_binding.tiller",
    "kubernetes_namespace.forseti",
    "google_service_account_iam_binding.forseti_server_service_account",
  "google_service_account_iam_binding.forseti_client_service_account"]

  set {
    name  = "cloudsqlConnection"
    value = module.cloudsql.forseti-cloudsql-connection-name
  }

  set {
    name  = "configValidator"
    value = var.config_validator_enabled
  }

  set {
    name  = "configValidatorImage"
    value = var.k8s_config_validator_image
  }

  set {
    name  = "configValidatorImageTag"
    value = var.k8s_config_validator_image_tag
  }

  set {
    name  = "gitSyncImage"
    value = var.git_sync_image
  }

  set {
    name  = "gitSyncImageTag"
    value = var.git_sync_image_tag
  }

  set_sensitive {
    name  = "gitSyncPrivateSSHKey"
    value = data.local_file.git_sync_private_key_file.content_base64
  }

  set {
    name  = "gitSyncWait"
    value = var.git_sync_wait
  }

  set {
    name  = "loadBalancer"
    value = var.load_balancer
  }

  set {
    name  = "networkPolicyEnable"
    value = var.network_policy
  }

  set {
    name  = "orchestratorImage"
    value = var.k8s_forseti_orchestrator_image
  }

  set {
    name  = "orchestratorImageTag"
    value = var.k8s_forseti_orchestrator_image_tag
  }

  set {
    name  = "production"
    value = var.production
  }

  set {
    name  = "policyLibraryRepositoryURL"
    value = var.policy_library_repository_url
  }

  set {
    name  = "policyLibraryRepositoryBranch"
    value = var.policy_library_repository_branch
  }

  set {
    name  = "serverImage"
    value = var.k8s_forseti_server_image
  }

  set {
    name  = "serverImageTag"
    value = var.k8s_forseti_server_image_tag
  }

  set {
    name  = "serverBucket"
    value = module.server_gcs.forseti-server-storage-bucket
  }

  set_string {
    name  = "serverConfigContents"
    value = "${base64encode(data.http.server_config_contents.body)}"
  }

  set {
    name  = "serverLogLevel"
    value = var.server_log_level
  }

  set {
    name  = "serverWorkloadIdentity"
    value = module.server_iam.forseti-server-service-account
  }

  set {
    name  = "orchestratorWorkloadIdentity"
    value = module.client_iam.forseti-client-service-account
  }

  set {
    name  = "forsetiRunFrequency"
    value = var.forseti_run_frequency
  }

  values = [
    "networkPolicyIngressCidr: [${var.network_policy_ingress_cidr}]"
  ]

}

//*****************************
//  Get the Ingress IP for the 
//  forseti-server service
//*****************************

data "kubernetes_service" "forseti_server" {
  metadata {
    name      = "forseti-server"
    namespace = var.k8s_forseti_namespace
  }
  depends_on = ["helm_release.forseti_security"]
}


