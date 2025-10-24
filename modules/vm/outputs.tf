# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "instance_id" {
  description = "The instance ID"
  value       = google_compute_instance.vm.instance_id
}

output "instance_name" {
  description = "The instance name"
  value       = google_compute_instance.vm.name
}

output "internal_ip" {
  description = "The internal IP address of the instance"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "self_link" {
  description = "The URI of the created resource"
  value       = google_compute_instance.vm.self_link
}

output "zone" {
  description = "The zone where the instance is deployed"
  value       = google_compute_instance.vm.zone
}

output "service_account_email" {
  description = "The email of the service account attached to the instance"
  value       = google_service_account.vm_sa.email
}

output "iap_ssh_command" {
  description = "Command to SSH into the instance via IAP"
  value       = "gcloud compute ssh ${google_compute_instance.vm.name} --zone=${google_compute_instance.vm.zone} --tunnel-through-iap"
}
