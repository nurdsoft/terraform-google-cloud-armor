variable "project_id" {
  description = "GCP project ID that owns the security policy."
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
  description = "Request paths that bypass all block rules. Entries ending in \"*\" use prefix matching (startsWith); all others use exact match. Set to an empty list to disable the path allowlist rule."
  type        = list(string)
  default     = ["/robots.txt", "/sitemap.xml", "/llms.txt"]
}

variable "allowed_user_agents" {
  description = "User-agent substrings (case-insensitive, joined into a single RE2 regex) that bypass all block rules. Use plain substrings; regex metacharacters must be pre-escaped by the caller. Set to an empty list to disable the UA allowlist rule."
  type        = list(string)
  default = [
    "gptbot",
    "chatgpt-user",
    "perplexitybot",
    "claudebot",
    "google-extended",
    "applebot",
    "bingbot",
    "googlebot",
    "duckduckbot",
    "yandexbot",
    "meta-externalagent",
  ]
}

variable "blocked_user_agents" {
  description = "User-agent substrings (case-insensitive, joined into a single RE2 regex) blocked with HTTP 403. Same escaping rules as allowed_user_agents. Set to an empty list to disable the scraper block rule."
  type        = list(string)
  default = [
    "python-requests",
    "scrapy",
    "wget",
    "ahrefsbot",
    "semrushbot",
    "dotbot",
    "mj12bot",
    "rogerbot",
    "majestic",
    "petalbot",
    "amazonbot",
    "ccbot",
    "blexbot",
    "bytespider",
  ]
}

variable "enable_sqli_protection" {
  description = "Enable Google's preconfigured SQL injection ruleset (sqli-v33-stable)."
  type        = bool
  default     = true
}

variable "sqli_sensitivity" {
  description = "Sensitivity level for the preconfigured SQLi ruleset. Range 0-4; higher values match more aggressively at the cost of more false positives."
  type        = number
  default     = 1

  validation {
    condition     = var.sqli_sensitivity >= 0 && var.sqli_sensitivity <= 4
    error_message = "sqli_sensitivity must be between 0 and 4 inclusive."
  }
}

variable "enable_rate_limit" {
  description = "Enable the per-IP rate limit rule."
  type        = bool
  default     = true
}

variable "rate_limit_threshold_count" {
  description = "Maximum requests per source IP within rate_limit_threshold_interval_sec before the rate limit action fires."
  type        = number
  default     = 100
}

variable "rate_limit_threshold_interval_sec" {
  description = "Rate limit window length in seconds."
  type        = number
  default     = 60
}

variable "preview_scraper_block" {
  description = "Run the scraper user-agent block rule in preview mode (log a verdict but do not deny)."
  type        = bool
  default     = false
}

variable "preview_sqli_block" {
  description = "Run the SQLi block rule in preview mode (log a verdict but do not deny)."
  type        = bool
  default     = false
}

variable "preview_rate_limit" {
  description = "Run the rate limit rule in preview mode (log a verdict but do not throttle)."
  type        = bool
  default     = false
}
