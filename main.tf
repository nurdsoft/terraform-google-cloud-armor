locals {
  # Escape backslash then single-quote so caller input can't break the surrounding CEL string literal.
  escaped_paths       = [for p in var.allowed_paths : replace(replace(p, "\\", "\\\\"), "'", "\\'")]
  escaped_allowed_uas = [for u in var.allowed_user_agents : replace(replace(u, "\\", "\\\\"), "'", "\\'")]
  escaped_blocked_uas = [for u in var.blocked_user_agents : replace(replace(u, "\\", "\\\\"), "'", "\\'")]

  path_allowlist_expr = join(" || ", [
    for p in local.escaped_paths :
    endswith(p, "*")
    ? format("request.path.startsWith('%s')", trimsuffix(p, "*"))
    : format("request.path == '%s'", p)
  ])

  allowed_ua_expr = format(
    "request.headers['user-agent'].matches('(?i)(?:%s)')",
    join("|", local.escaped_allowed_uas),
  )

  blocked_ua_expr = format(
    "request.headers['user-agent'].matches('(?i)(?:%s)')",
    join("|", local.escaped_blocked_uas),
  )
}

resource "google_compute_security_policy" "this" {
  project     = var.project_id
  name        = var.name
  description = var.description
  type        = "CLOUD_ARMOR"

  dynamic "rule" {
    for_each = length(var.allowed_paths) > 0 ? [1] : []
    content {
      action      = "allow"
      priority    = 500
      preview     = var.preview_path_allowlist
      description = "Path allowlist"
      match {
        expr {
          expression = local.path_allowlist_expr
        }
      }
    }
  }

  dynamic "rule" {
    for_each = length(var.allowed_user_agents) > 0 ? [1] : []
    content {
      action      = "allow"
      priority    = 1000
      preview     = var.preview_ua_allowlist
      description = "User-agent allowlist"
      match {
        expr {
          expression = local.allowed_ua_expr
        }
      }
    }
  }

  dynamic "rule" {
    for_each = length(var.blocked_user_agents) > 0 ? [1] : []
    content {
      action      = "deny(403)"
      priority    = 2000
      preview     = var.preview_scraper_block
      description = "Block scraper user-agents"
      match {
        expr {
          expression = local.blocked_ua_expr
        }
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_sqli_protection ? [1] : []
    content {
      action      = "deny(403)"
      priority    = 3000
      preview     = var.preview_sqli_block
      description = "Block SQL injection (OWASP sqli-v33-stable)"
      match {
        expr {
          expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': ${var.sqli_sensitivity}})"
        }
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_rate_limit ? [1] : []
    content {
      action      = "throttle"
      priority    = 4000
      preview     = var.preview_rate_limit
      description = "Rate limit per source IP"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = ["*"]
        }
      }
      rate_limit_options {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        enforce_on_key = "IP"
        rate_limit_threshold {
          count        = var.rate_limit_threshold_count
          interval_sec = var.rate_limit_threshold_interval_sec
        }
      }
    }
  }

  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow rule"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
