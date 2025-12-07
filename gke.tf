# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "google_compute_zones" "available" {}

data "google_container_engine_versions" "gke_version" {
  location       = var.region
  version_prefix = var.gke_version_prefix
}

locals {
  workload_pool = "${var.google_project}.svc.id.goog"
}

resource "google_container_cluster" "engineering" {
  name     = var.cluster_name
  location = data.google_compute_zones.available.names.0

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  enable_shielded_nodes = var.enable_pow_security
  datapath_provider     = "ADVANCED_DATAPATH"

  release_channel {
    channel = "STABLE"
  }

  workload_identity_config {
    workload_pool = local.workload_pool
  }

  binary_authorization {
    evaluation_mode = var.enable_pow_security ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  security_posture_config {
    mode               = var.enable_pow_security ? "BASIC" : "DISABLED"
    vulnerability_mode = var.enable_pow_security ? "VULNERABILITY_BASIC" : "VULNERABILITY_DISABLED"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {}
}

resource "google_container_node_pool" "engineering_preemptible_nodes" {
  name     = "${var.cluster_name}-node-pool"
  cluster  = google_container_cluster.engineering.name
  location = data.google_compute_zones.available.names.0

  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.node_count

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = var.enable_pow_security
      enable_integrity_monitoring = var.enable_pow_security
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}