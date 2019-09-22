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


variable "org_id" {
  description = "GCP Organization ID that Forseti will have purview over"
}

variable "domain" {
  description = "The domain associated with the GCP Organization ID"
}

variable "project_id" {
  description = "The ID of an existing Google project where Forseti will be installed"
}

variable "network" {
  description = "Name of the shared VPC"
  default     = "forseti-gke-network"
}

variable "subnetwork" {
  description = "Name of the subnetwork where forseti will be deployed"
  default     = "forseti-gke-network"
}

variable "region" {
  description = "Region where forseti subnetwork will be deployed"
  default     = "us-central1"
}

variable "zones" {
  description = "The zones to host the cluster in. This is optional if the GKE cluster is regional.  It is required if the cluster is zonal."
  default     = ["us-central1-a"]
}

variable "gsuite_admin_email" {
  description = "G-Suite administrator email address to manage your Forseti installation"
}

variable "config_validator_enabled" {
  description = "Config Validator scanner enabled."
  type        = bool
  default     = false
}

variable "git_sync_private_key_file" {
  description = "The file path to the private key used for an SSH connection to the hosted Git repository."
}

variable "gke_cluster_name" {
  description = "The name of the GKE Cluster"
  default     = "forseti-cluster"
}

variable "gke_node_ip_range" {
  description = "The IP range for the GKE nodes."
  default     = "10.1.0.0/20"
}

variable "gke_pod_ip_range" {
  description = "The IP range of the Kubernetes pods"
  default     = "10.2.0.0/20"
}

variable "gke_service_account" {
  description = "The service account to run nodes as if not overridden in node_pools. The default value will cause a cluster-specific service account to be created."
  default     = "create"
}

variable "gke_service_ip_range" {
  description = "The IP range of the Kubernetes services."
  default     = "10.3.0.0/20"
}

variable "k8s_forseti_namespace" {
  description = "The Kubernetes namespace in which to deploy Forseti."
  default     = "forseti"
}

variable "k8s_tiller_sa_name" {
  description = "The Kubernetes Service Account used by Tiller"
  default     = "tiller"
}

variable "load_balancer" {
  description = "The type of load balancer to deploy for the forseti-server if desired: none, external, internal"
  default     = "internal"
}

variable "production" {
  description = "Whether or not to deploy Forseti on GKE in a production configuration"
  type        = bool
  default     = true
}

variable "policy_library_repository_url" {
  description = "The git repository containing the policy-library.  Must be set if deploying config-validator"
}

variable "policy_library_repository_branch" {
  description = "The specific git branch containing the policies."
  default     = "master"
}

variable "network_description" {
  type        = string
  description = "An optional description of the network. The resource must be recreated to modify this field."
  default     = ""
}

variable "auto_create_subnetworks" {
  description = "When set to true, the network is created in 'auto subnet mode' and it will create a subnet for each region automatically across the 10.128.0.0/9 address range. When set to false, the network is created in 'custom subnet mode' so the user can explicitly connect subnetwork resources."
  type        = bool
  default     = false
}

variable "server_log_level" {
  description = "The log level of the Forseti server container."
  default     = "info"
}

variable "sendgrid_api_key" {
  description = "Sendgrid API key."
  default     = ""
}

variable "forseti_email_sender" {
  description = "Forseti email sender."
  default     = ""
}

variable "forseti_email_recipient" {
  description = "Forseti email recipient."
  default     = ""
}
