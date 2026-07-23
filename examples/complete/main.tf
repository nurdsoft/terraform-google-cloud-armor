module "cloud_armor" {
  source = "git::https://github.com/nurdsoft/terraform-google-cloud-armor.git?ref=v0.1.0"

  project_id  = "my-gcp-project"
  name        = "my-app-armor-policy"
  description = "WAF for my-app frontend load balancer"

  allowed_paths = [
    "/robots.txt",
    "/sitemap*",
    "/llms.txt",
    "/.well-known/*",
  ]

  allowed_user_agents = [
    "gptbot",
    "chatgpt-user",
    "perplexitybot",
    "claudebot",
    "google-extended",
    "googlebot",
    "bingbot",
    "duckduckbot",
  ]

  blocked_user_agents = [
    "python-requests",
    "scrapy",
    "wget",
    "ahrefsbot",
    "semrushbot",
    "bytespider",
  ]

  enable_sqli_protection = true
  sqli_sensitivity       = 2

  enable_rate_limit                 = true
  rate_limit_threshold_count        = 200
  rate_limit_threshold_interval_sec = 60

  preview_scraper_block = true
  preview_sqli_block    = true
  preview_rate_limit    = true
}

resource "google_compute_backend_service" "example" {
  project         = "my-gcp-project"
  name            = "my-app-backend"
  security_policy = module.cloud_armor.self_link
}
