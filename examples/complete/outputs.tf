output "id" {
  description = "The ID of the security policy."
  value       = module.cloud_armor.id
}

output "name" {
  description = "The name of the security policy."
  value       = module.cloud_armor.name
}

output "self_link" {
  description = "URI of the security policy. Assign to google_compute_backend_service.security_policy to attach."
  value       = module.cloud_armor.self_link
}
