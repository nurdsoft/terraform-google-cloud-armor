variable "project_id" {
  description = "The GCP project ID that owns the security policy."
  type        = string
}

variable "name" {
  description = "Name of the security policy. Must be unique within the project."
  type        = string
}

variable "description" {
  description = "Human-readable description for the security policy."
  type        = string
  default     = "Cloud Armor security policy managed by terraform-google-cloud-armor."
}

variable "allowed_paths" {
  description = "Request paths that bypass all block rules. Entries ending in \"*\" use prefix matching."
  type        = list(string)
  default     = ["/robots.txt", "/sitemap.xml", "/llms.txt"]
}

variable "allowed_user_agents" {
  description = "User-agent substrings (case-insensitive) that bypass all block rules."
  type        = list(string)
  default = [
    "gptbot",
    "chatgpt-user",
    "perplexitybot",
    "claudebot",
    "google-extended",
    "googlebot",
    "bingbot",
    "duckduckbot",
  ]
}

variable "blocked_user_agents" {
  description = "User-agent substrings (case-insensitive) blocked with HTTP 403."
  type        = list(string)
  default = [
    "python-requests",
    "scrapy",
    "wget",
    "ahrefsbot",
    "semrushbot",
    "bytespider",
  ]
}

variable "enable_sqli_protection" {
  description = "Enable the preconfigured SQL injection ruleset."
  type        = bool
  default     = true
}

variable "sqli_sensitivity" {
  description = "Sensitivity level for the SQLi ruleset (0-4)."
  type        = number
  default     = 2
}

variable "enable_rate_limit" {
  description = "Enable the per-IP rate limit rule."
  type        = bool
  default     = true
}

variable "rate_limit_threshold_count" {
  description = "Requests per source IP per interval before rate limit fires."
  type        = number
  default     = 200
}

variable "rate_limit_threshold_interval_sec" {
  description = "Rate limit window length in seconds."
  type        = number
  default     = 60
}

variable "preview_path_allowlist" {
  description = "Run the path allowlist rule in preview mode."
  type        = bool
  default     = true
}

variable "preview_ua_allowlist" {
  description = "Run the user-agent allowlist rule in preview mode."
  type        = bool
  default     = true
}

variable "preview_scraper_block" {
  description = "Run the scraper block rule in preview mode."
  type        = bool
  default     = true
}

variable "preview_sqli_block" {
  description = "Run the SQLi block rule in preview mode."
  type        = bool
  default     = true
}

variable "preview_rate_limit" {
  description = "Run the rate limit rule in preview mode."
  type        = bool
  default     = true
}
