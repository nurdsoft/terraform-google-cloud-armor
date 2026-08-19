project_id  = "your-project-id"
name        = "example-armor-policy"
description = "Cloud Armor security policy managed by Terraform."

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

preview_path_allowlist = true
preview_ua_allowlist   = true
preview_scraper_block  = true
preview_sqli_block     = true
preview_rate_limit     = true
