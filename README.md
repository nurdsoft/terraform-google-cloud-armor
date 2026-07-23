# terraform-google-cloud-armor

## Overview

This Terraform module provisions a GCP [Cloud Armor](https://cloud.google.com/armor) `google_compute_security_policy` with a layered rule set aimed at frontend load balancers: path allowlist, user-agent allowlist for search / AI crawlers, scraper user-agent block, OWASP SQL-injection ruleset, and a per-IP rate limit. Every rule is toggleable and every list is overridable, so the same module fits both minimal single-tenant setups and richer configurations.

The module output `self_link` is designed to be assigned to `google_compute_backend_service.security_policy` (see the complete example).

## Rule layout

| Priority   | Action        | Purpose                                          | Toggle                              |
|-----------:|---------------|--------------------------------------------------|-------------------------------------|
| 500        | allow         | Path allowlist (bypass all block rules)          | `allowed_paths` (empty → skipped)   |
| 1000       | allow         | User-agent allowlist (bypass all block rules)    | `allowed_user_agents` (empty → skipped) |
| 2000       | deny(403)     | Block known scraper user-agents                  | `blocked_user_agents` (empty → skipped) |
| 3000       | deny(403)     | Preconfigured SQL injection ruleset              | `enable_sqli_protection`            |
| 4000       | throttle→429  | Per-source-IP rate limit                         | `enable_rate_limit`                 |
| 2147483647 | allow         | Default rule                                     | always present                      |

Each block rule has a matching `preview_*` variable that runs the rule in shadow mode (verdicts land in Cloud Logging but no traffic is denied), which is useful during initial rollout.

## Usage

`Minimal (defaults)`:

```hcl
module "cloud_armor" {
  source = "git::https://github.com/nurdsoft/terraform-google-cloud-armor.git?ref=v0.1.0"

  project_id = "my-gcp-project"
  name       = "my-app-armor-policy"
}
```

`Attaching to a backend service`:

```hcl
module "cloud_armor" {
  source = "git::https://github.com/nurdsoft/terraform-google-cloud-armor.git?ref=v0.1.0"

  project_id = "my-gcp-project"
  name       = "my-app-armor-policy"
}

resource "google_compute_backend_service" "app" {
  project         = "my-gcp-project"
  name            = "my-app-backend"
  security_policy = module.cloud_armor.self_link
  # ... remaining backend service configuration
}
```

`Preview mode during rollout`:

```hcl
module "cloud_armor" {
  source = "git::https://github.com/nurdsoft/terraform-google-cloud-armor.git?ref=v0.1.0"

  project_id = "my-gcp-project"
  name       = "my-app-armor-policy"

  preview_scraper_block = true
  preview_sqli_block    = true
  preview_rate_limit    = true
}
```

See [examples/complete](./examples/complete) for the full surface area.

## Notes on user-agent expressions

Both `allowed_user_agents` and `blocked_user_agents` are joined into a single case-insensitive RE2 regex of the form `(?i)(?:ua1|ua2|...)`. Cloud Armor's RE2 engine rejects capture groups, so the module wraps the alternation in a non-capturing group (`(?:...)`). Callers passing regex metacharacters (`.`, `*`, `+`, etc.) must pre-escape them.

Very long lists risk exceeding Cloud Armor's per-expression length limit (currently 2048 characters). If you hit that limit, split into narrower lists and file follow-up rules directly against the policy resource output.

## Assumptions

- A basic understanding of [Git](https://git-scm.com/). Git version `>= 2.33.0`.
- A GCP identity with permission to create/update/delete `google_compute_security_policy` resources in the target project.
- [GCloud CLI](https://cloud.google.com/sdk/docs/install) `>= 465.0.0`
- A basic understanding of [Terraform](https://www.terraform.io/). Terraform version `>= 1.3`.

## Test

```sh
gcloud init
gcloud auth application-default login
cd examples/minimal
terraform init
terraform plan
terraform apply
terraform destroy
```

## Contributions

Contributions are always welcome. As such, this project uses the `main` branch as the source of truth to track changes.

**Step 1**. Clone this project.

```sh
# Using Git
$ git clone git@github.com:nurdsoft/terraform-google-cloud-armor.git

# Using HTTPS
$ git clone https://github.com/nurdsoft/terraform-google-cloud-armor.git
```

**Step 2**. Checkout a feature branch: `git checkout -b feat/abc`.

**Step 3**. Validate the change/s locally by executing the steps defined under [Test](#test).

**Step 4**. If testing is successful, commit and push the new change/s to the remote.

```sh
$ git add file1 file2 ...

$ git commit -m "Adding some change"

$ git push --set-upstream origin feat/abc
```

**Step 5**. Once pushed, create a [PR](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) and assign it to a member for review.

- **Important Note**: It can be helpful to attach the `terraform plan` output in the PR.

**Step 6**. A team member reviews/approves/merges the change/s.

**Step 7**. Once merged, deploy the required changes as needed.

**Step 8**. Once deployed, verify that the changes have been deployed.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| google | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | GCP project ID that owns the security policy | `string` | n/a | yes |
| name | Name of the security policy. Must be unique within the project | `string` | n/a | yes |
| description | Human-readable description for the security policy | `string` | `"Cloud Armor security policy managed by terraform-google-cloud-armor."` | no |
| allowed\_paths | Request paths that bypass all block rules. Entries ending in `*` use prefix matching (`startsWith`); all others use exact match. Empty list → rule skipped | `list(string)` | `["/robots.txt", "/sitemap.xml", "/llms.txt"]` | no |
| allowed\_user\_agents | User-agent substrings (case-insensitive) that bypass all block rules. Empty list → rule skipped | `list(string)` | AI/LLM + major search crawlers | no |
| blocked\_user\_agents | User-agent substrings (case-insensitive) blocked with HTTP 403. Empty list → rule skipped | `list(string)` | common scrapers | no |
| enable\_sqli\_protection | Enable Google's preconfigured SQLi ruleset (`sqli-v33-stable`) | `bool` | `true` | no |
| sqli\_sensitivity | Sensitivity level for the SQLi ruleset. Range 0-4 | `number` | `1` | no |
| enable\_rate\_limit | Enable the per-IP rate limit rule | `bool` | `true` | no |
| rate\_limit\_threshold\_count | Requests per source IP per interval before rate limit fires | `number` | `100` | no |
| rate\_limit\_threshold\_interval\_sec | Rate limit window length in seconds | `number` | `60` | no |
| preview\_scraper\_block | Run the scraper block rule in preview mode | `bool` | `false` | no |
| preview\_sqli\_block | Run the SQLi block rule in preview mode | `bool` | `false` | no |
| preview\_rate\_limit | Run the rate limit rule in preview mode | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the security policy |
| name | The name of the security policy |
| self\_link | The URI/self link of the security policy. Assign to `google_compute_backend_service.security_policy` to attach |

## Authors

Module is maintained by [Nurdsoft](https://github.com/nurdsoft).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/nurdsoft/terraform-google-cloud-armor/blob/main/LICENSE) for full details.
