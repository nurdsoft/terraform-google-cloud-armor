output "id" {
  description = "The ID of the security policy."
  value       = google_compute_security_policy.this.id
}

output "name" {
  description = "The name of the security policy."
  value       = google_compute_security_policy.this.name
}

output "self_link" {
  description = "The URI/self link of the security policy. Assign to google_compute_backend_service.security_policy to attach."
  value       = google_compute_security_policy.this.self_link
}
