# -----------------------------------------------------------------------------
# Example: Cloud Armor
#
# End-to-end usage of terraform-google-cloud-armor. Provisions a security
# policy with every input exercised, then wires the policy self_link into a
# google_compute_backend_service to illustrate attachment.
# -----------------------------------------------------------------------------

module "cloud_armor" {
  source = "../.."

  project_id  = var.project_id
  name        = var.name
  description = var.description

  allowed_paths       = var.allowed_paths
  allowed_user_agents = var.allowed_user_agents
  blocked_user_agents = var.blocked_user_agents

  enable_sqli_protection = var.enable_sqli_protection
  sqli_sensitivity       = var.sqli_sensitivity

  enable_rate_limit                 = var.enable_rate_limit
  rate_limit_threshold_count        = var.rate_limit_threshold_count
  rate_limit_threshold_interval_sec = var.rate_limit_threshold_interval_sec

  preview_path_allowlist = var.preview_path_allowlist
  preview_ua_allowlist   = var.preview_ua_allowlist
  preview_scraper_block  = var.preview_scraper_block
  preview_sqli_block     = var.preview_sqli_block
  preview_rate_limit     = var.preview_rate_limit
}
