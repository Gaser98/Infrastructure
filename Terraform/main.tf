# Configure Google Cloud provider
provider "google" {
  credentials = file("porjectg-iti-bf924d32a8e1.json")
  project     = "porjectg-iti"
  region      = "us-east1"
}
# Create VPC network
resource "google_compute_network" "vpc" {
  name                    = "vpc1"
  auto_create_subnetworks = false
}

# Create subnet for GKE cluster
resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.self_link
  
}

# Create GKE cluster
resource "google_container_cluster" "primary" {
  name                     = "my-gke-cluster"
  location                 = "us-east1-b"
  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.subnet.name
  remove_default_node_pool = true 
  initial_node_count = 1

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "10.13.0.0/28"
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.11.0.0/21"
    services_ipv4_cidr_block = "10.12.0.0/21"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.7/32"
      display_name = "net1"
    }

  }
}

# Create managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = "us-east1-b"
  cluster    = google_container_cluster.primary.name
  node_count = 3

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "dev"
    }

    machine_type = "n1-standard-1"
    preemptible  = true
    

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
# Create jump host 
resource "google_compute_address" "my_internal_ip_addr" {
  project      = "porjectg-iti"
  address_type = "INTERNAL"
  region       = "us-east1"
  subnetwork   = google_compute_subnetwork.subnet.name
  name         = "my-ip"
  address      = "10.0.0.7"
  description  = "An internal IP address for my jump host"
}

resource "google_compute_instance" "default" {
  project      = "porjectg-iti"
  zone         = "us-east1-b"
  name         = "jump-host"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = "vpc1"
    subnetwork = "my-subnet" 
    network_ip         = google_compute_address.my_internal_ip_addr.address
  }

}


# Create Firewall to access jump host via iap
resource "google_compute_firewall" "rules" {
  project = "porjectg-iti"
  name    = "allow-ssh"
  network = google_compute_network.vpc.name 

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}
resource "google_compute_router_nat" "cloud_nat" {
  name                  = "my-cloud-nat"
  router                = google_compute_router.vpc_router.name
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_router" "vpc_router" {
  name    = "my-vpc-router"
  network = google_compute_network.vpc.name
}
resource "google_compute_address" "nat_address" {
  name = "my-nat-ip"
  region =  "us-east1"
}






