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

output "suffix" {
  description = "The random suffix appended to Forseti resources"
  value       = module.forseti.suffix
}

output "forseti-server-service-account" {
  description = "Forseti Server service account"
  value       = module.forseti.forseti-server-service-account
}

output "forseti-server-storage-bucket" {
  description = "Forseti Server storage bucket"
  value       = module.forseti.forseti-server-storage-bucket
}

output "forseti-server-git-public-key-openssh" {
  description = "The public OpenSSH key generated to allow the Forseti Server to clone the policy library repository."
  value       = module.forseti.forseti-server-git-public-key-openssh
}

output "forseti-load-balancer-ingress" {
  description = "A list containing ingress points for the load-balancer (only valid if load_balancer is internal or external)."
  value       = module.forseti.forseti-load-balancer-ingress
}
