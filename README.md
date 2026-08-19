# terraform-google-cloud-armor

A Terraform module for provisioning a GCP [Cloud Armor](https://cloud.google.com/armor) `google_compute_security_policy` with a layered, opinionated rule stack — path allowlist, user-agent allowlist for search / AI crawlers, scraper user-agent block, OWASP SQL-injection ruleset, and per-IP rate limit — for attachment to a `google_compute_backend_service` in front of an HTTPS load balancer.

## Features

- Path allowlist (P500) — exact `==` and `startsWith` matching in a single list
- User-agent allowlist (P1000) — case-insensitive, non-capturing-group RE2 regex generated from a plain substring list
- Scraper user-agent block (P2000) — same regex generation, HTTP 403
- OWASP SQL-injection ruleset (P3000) — preconfigured `sqli-v33-stable`, tunable sensitivity
- Per-IP rate limit (P4000) — configurable count + interval, `throttle → deny(429)`
- Default allow rule (P2147483647) — always present
- Every list is overridable; every block rule has a matching `preview_*` toggle for shadow-mode rollout
- Every optional rule can be disabled by clearing its list or flipping its `enable_*` flag

---

## Assumptions

- A basic understanding of [Git](https://git-scm.com/).
- Git version `>= 2.33.0`.
- An existing GCP IAM user or service account with permissions to create/update/delete the resources defined in [main.tf](https://github.com/nurdsoft/terraform-google-cloud-armor/blob/main/main.tf).
- [GCloud CLI](https://cloud.google.com/sdk/docs/install) `>= 465.0.0`.
- A basic understanding of [Terraform](https://www.terraform.io/).
- Terraform version `>= 1.3.0`.
- (Optional — for local testing) A basic understanding of [Make](https://www.gnu.org/software/make/manual/make.html#Introduction).
  - Make version `>= GNU Make 3.81`.
  - **Important Note**: This project includes a [Makefile](https://github.com/nurdsoft/terraform-google-cloud-armor/blob/main/Makefile) to speed up local development in Terraform. The `make` targets act as a wrapper around Terraform commands. As such, `make` has only been tested/verified on **Linux/Mac OS**. Though, it is possible to [install make using Chocolatey](https://community.chocolatey.org/packages/make), we **do not** guarantee this approach as it has not been tested/verified. You may use the commands in the [Makefile](https://github.com/nurdsoft/terraform-google-cloud-armor/blob/main/Makefile) as a guide to run each Terraform command locally on Windows.

---

## Test

**Important Note**: This project includes a [Makefile](https://github.com/nurdsoft/terraform-google-cloud-armor/blob/main/Makefile) to speed up local development in Terraform. The `make` targets act as a wrapper around Terraform commands. As such, `make` has only been tested/verified on **Linux/Mac OS**. Though, it is possible to [install make using Chocolatey](https://community.chocolatey.org/packages/make), we **do not** guarantee this approach as it has not been tested/verified. You may use the commands in the [Makefile](https://github.com/nurdsoft/terraform-google-cloud-armor/blob/main/Makefile) as a guide to run each Terraform command locally on Windows.

```sh
gcloud init # https://cloud.google.com/docs/authentication/gcloud
gcloud auth application-default login

# Copy the example tfvars and customize it
cp examples/complete/examples.tfvars examples/complete/terraform.tfvars
# Edit terraform.tfvars with your values

# Run terraform commands
make plan
make apply
make destroy
```

---

## Contributions

Contributions are always welcome. As such, this project uses the `main` branch as the source of truth to track changes.

**Step 1**. Clone this project.

```sh
# Using SSH
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

- If possible, please add a `plan` output using the feature branch so the member reviewing the PR has better visibility into the changes.

---

## Usage

```hcl
module "cloud_armor" {
  source = "git::https://github.com/nurdsoft/terraform-google-cloud-armor.git?ref=main"

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

### Rule layout

| Priority   | Action        | Purpose                                          | Toggle                                          |
|-----------:|---------------|--------------------------------------------------|-------------------------------------------------|
| 500        | allow         | Path allowlist (bypass all block rules)          | `allowed_paths` (empty → rule skipped)          |
| 1000       | allow         | User-agent allowlist (bypass all block rules)    | `allowed_user_agents` (empty → rule skipped)    |
| 2000       | deny(403)     | Block known scraper user-agents                  | `blocked_user_agents` (empty → rule skipped)    |
| 3000       | deny(403)     | Preconfigured SQL injection ruleset              | `enable_sqli_protection`                        |
| 4000       | throttle→429  | Per-source-IP rate limit                         | `enable_rate_limit`                             |
| 2147483647 | allow         | Default rule                                     | always present                                  |

### Notes on user-agent expressions

Both `allowed_user_agents` and `blocked_user_agents` are joined into a single case-insensitive RE2 regex of the form `(?i)(?:ua1|ua2|...)`. Cloud Armor's RE2 engine rejects capture groups, so the module wraps the alternation in a non-capturing group. Callers passing regex metacharacters (`.`, `*`, `+`, etc.) must pre-escape them. Very long lists risk exceeding Cloud Armor's per-expression length limit (currently 2048 characters).

## Examples

| Example | Description |
|---|---|
| [complete](./examples/complete) | Full setup with every input exercised and preview mode enabled on all block rules |

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3 |
| google | ~> 5.0 |

## Providers

| Name | Version |
|---|---|
| [google](https://registry.terraform.io/providers/hashicorp/google/latest) | ~> 5.0 |

## Inputs

### Required

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_id` | GCP project ID that owns the security policy. | `string` | n/a | yes |
| `name` | Name of the security policy. Must be unique within the project. | `string` | n/a | yes |

### Optional

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `description` | Human-readable description for the security policy. | `string` | `"Cloud Armor security policy managed by Terraform."` | no |
| `allowed_paths` | Request paths that bypass all block rules. Entries ending in `*` use prefix matching (`startsWith`); others use exact match. Empty list → rule skipped. | `list(string)` | `["/robots.txt", "/sitemap.xml", "/llms.txt"]` | no |
| `allowed_user_agents` | User-agent substrings (case-insensitive) that bypass all block rules. Empty list → rule skipped. | `list(string)` | AI/LLM + major search crawlers | no |
| `blocked_user_agents` | User-agent substrings (case-insensitive) blocked with HTTP 403. Empty list → rule skipped. | `list(string)` | common scrapers | no |
| `enable_sqli_protection` | Enable Google's preconfigured SQLi ruleset (`sqli-v33-stable`). | `bool` | `true` | no |
| `sqli_sensitivity` | Sensitivity level for the SQLi ruleset. Range 0-4. | `number` | `1` | no |
| `enable_rate_limit` | Enable the per-IP rate limit rule. | `bool` | `true` | no |
| `rate_limit_threshold_count` | Requests per source IP per interval before rate limit fires. | `number` | `100` | no |
| `rate_limit_threshold_interval_sec` | Rate limit window length in seconds. | `number` | `60` | no |
| `preview_path_allowlist` | Run the path allowlist rule in preview mode. | `bool` | `false` | no |
| `preview_ua_allowlist` | Run the user-agent allowlist rule in preview mode. | `bool` | `false` | no |
| `preview_scraper_block` | Run the scraper block rule in preview mode. | `bool` | `false` | no |
| `preview_sqli_block` | Run the SQLi block rule in preview mode. | `bool` | `false` | no |
| `preview_rate_limit` | Run the rate limit rule in preview mode. | `bool` | `false` | no |

## Outputs

| Name | Description |
|---|---|
| `id` | The ID of the security policy. |
| `name` | The name of the security policy. |
| `self_link` | URI of the security policy. Assign to `google_compute_backend_service.security_policy` to attach. |

## Authors

Module is maintained by [Nurdsoft](https://github.com/nurdsoft).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/nurdsoft/terraform-google-cloud-armor/blob/main/LICENSE) for full details.
