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

output "forseti-server-git-public-key-openssh" {
  description = "The public OpenSSH key generated to allow the Forseti Server to clone the policy library repository."
  value       = tls_private_key.policy_library_sync_ssh.public_key_openssh
}

output "forseti-server-storage-bucket" {
  description = "Forseti Server storage bucket"
  value       = module.server_gcs.forseti-server-storage-bucket
}

output "forseti-server-service-account" {
  description = "Forseti Server service account"
  value       = module.server_iam.forseti-server-service-account
}

output "suffix" {
  description = "The random suffix appended to Forseti resources"
  value       = local.random_hash
}

output "forseti-load-balancer-ingress" {
  description = "A list containing ingress points for the load-balancer (only valid if load_balancer is internal or external)."
  value       = data.kubernetes_service.forseti_server.load_balancer_ingress[0]["ip"]
}
