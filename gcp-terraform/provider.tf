terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.21.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.21.0"
    }
  }

  # ─── Remote State in GCS ──────────────────────────────────────────────────────
  backend "gcs" {
    bucket = "hungtp-gcp-project" 
    prefix = "terraform/state"
  }
}

provider "google" {
  project     = var.project-id
  region      = var.region
  credentials = file(var.credentials-file)
}

provider "google-beta" {
  project     = var.project-id
  region      = var.region
  credentials = file(var.credentials-file)
}
