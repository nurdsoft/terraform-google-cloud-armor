module "cloud_armor" {
  source = "git::https://github.com/nurdsoft/terraform-google-cloud-armor.git?ref=v0.1.0"

  project_id = "my-gcp-project"
  name       = "my-app-armor-policy"
}
