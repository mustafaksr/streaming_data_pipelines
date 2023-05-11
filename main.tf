terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.55.0"
    }
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.9.0"
    }
    
  }
  
}

provider "google" {
  project     = var.gcp_project_id
  region      = var.region
  zone        = var.zone
}

provider "mongodbatlas" {
  public_key  = var.mongodb_public_key
  private_key = var.mongodb_private_key
}

# get current project
data "google_project" "my_project" {
}

resource "google_project_iam_member" "cloud_build_storage_viewer" {
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_project.my_project.number}@cloudbuild.gserviceaccount.com"
  
}

resource "google_project_iam_member" "compute_storage_viewer" {
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_project.my_project.number}-compute@developer.gserviceaccount.com"
  
}

# Get default Google Network
data "google_compute_network" "default" {
  name = "default"
  
}

resource "google_compute_firewall" "mongodb" {
  name    = "mongodb"
  network = data.google_compute_network.default.self_link
  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }
  
}
# Get default Google Sub Network
data "google_compute_subnetwork" "default" {
  name   = "default"
  region = "us-east1"
}

resource "google_pubsub_topic" "syntetic-data" {
  name = "syntetic-data"
  project = var.gcp_project_id
}

resource "google_pubsub_subscription" "syntetic-data-sub" {
  name  = "syntetic-data-sub"
  topic = google_pubsub_topic.syntetic-data.name
  
}

resource "google_storage_bucket" "stage_bucket" {
  name     = var.gcp_project_id
  location      = "US"
  force_destroy = true
  
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  
}

# Create a Mongodb Atlas Project
resource "mongodbatlas_project" "atlas-project" {
  org_id = var.atlas_org_id
  name = var.atlas_project_name
}

resource "mongodbatlas_network_container" "test" {
  project_id       = mongodbatlas_project.atlas-project.id
  atlas_cidr_block = "10.8.0.0/18"
  provider_name    = "GCP"
  
}

# Create the peering connection request
resource "mongodbatlas_network_peering" "test" {
  project_id     = mongodbatlas_project.atlas-project.id
  container_id   = mongodbatlas_network_container.test.container_id
  provider_name  = "GCP"
  gcp_project_id = var.gcp_project_id
  network_name   = "default"
}

# Create the GCP peer
resource "google_compute_network_peering" "peering" {
  name         = "peering-gcp-terraform-test"
  network      = data.google_compute_network.default.self_link
  peer_network = "https://www.googleapis.com/compute/v1/projects/${mongodbatlas_network_peering.test.atlas_gcp_project_id}/global/networks/${mongodbatlas_network_peering.test.atlas_vpc_name}"
}

resource "mongodbatlas_cluster" "mongodb_cluster" {
  project_id   = mongodbatlas_project.atlas-project.id
  name         = "synteticCluster"
  cluster_type = "REPLICASET"
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "EASTERN_US"
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }
  # Provider Settings "block"
  provider_name               = "GCP"
  provider_instance_size_name = "M10"
  depends_on = ["google_compute_network_peering.peering"]
}

resource "mongodbatlas_database_user" "mongodb_cluster" {
  username = var.mongodb_username
  password = var.mongodb_password
  project_id = mongodbatlas_project.atlas-project.id
  auth_database_name = "admin"
  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
}

data "mongodbatlas_cluster" "mongodb_cluster" {
  project_id = mongodbatlas_project.atlas-project.id
  name       = "synteticCluster"
}

resource "mongodbatlas_project_ip_access_list" "test" {
  project_id = mongodbatlas_project.atlas-project.id
  cidr_block = "${join(".",slice(split(".",data.google_compute_subnetwork.default.gateway_address),0,3))}.0/18"
  comment    = "cidr block for tf acc testing"
}

output "outputs" { value = {
    
    "PROJECT_ID"  : "${var.gcp_project_id}",
    "DATABASE_NAME" : "mydata",
    "COLLECTION_NAME" : "mycoll",
    "DB_USER" : "${var.mongodb_username}",
    "DB_PASSWORD"   : "${var.mongodb_password}",
    "MONGODB_URI_FOR_TEST"      = "mongodb+srv://${var.mongodb_username}:${var.mongodb_password}@${split("-",split("://", mongodbatlas_cluster.mongodb_cluster.mongo_uri)[1])[0]}.${join(".",slice(split(".",split(":",split("://", mongodbatlas_cluster.mongodb_cluster.mongo_uri)[1])[0]),1,4))}/?retryWrites=true&w=majority",
    "MONGODB_URI_FOR_PRIVATE"      = "mongodb+srv://${var.mongodb_username}:${var.mongodb_password}@${split("-",split("://", mongodbatlas_cluster.mongodb_cluster.mongo_uri)[1])[0]}-pri.${join(".",slice(split(".",split(":",split("://", mongodbatlas_cluster.mongodb_cluster.mongo_uri)[1])[0]),1,4))}/?retryWrites=true&w=majority",
    "IP_ACCESS_CIDR_BLOCK":"${join(".",slice(split(".",data.google_compute_subnetwork.default.gateway_address),0,3))}.0/18"
}}

