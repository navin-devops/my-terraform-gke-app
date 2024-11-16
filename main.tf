provider "google" {
  project     = "gleaming-lead-438006-g4"
  region      = "us-central1"
  zone        = "us-central1-a"
}

# 1. Create the GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "my-cluster"
  location = "us-central1-a"

  initial_node_count = 1

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  remove_default_node_pool = true
  enable_network_policy    = true
}

# 2. Create Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "default-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 40
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

# 3. Data source to fetch cluster credentials for kubectl config
data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location
}

# 4. Output kubeconfig for use with kubectl
output "kubeconfig" {
  value = data.google_container_cluster.primary.kube_config_raw
}

# 5. Configure Kubernetes provider using the GKE cluster's kubeconfig
provider "kubernetes" {
  host                   = data.google_container_cluster.primary.endpoint
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  token                  = data.google_container_cluster.primary.master_auth[0].access_token
}

# 6. Create a Kubernetes namespace for your app
resource "kubernetes_namespace" "default" {
  metadata {
    name = "default"
  }
}

# 7. Create a Kubernetes deployment for the app (build the image locally or from a container registry)
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "example-app"
    namespace = kubernetes_namespace.default.metadata[0].name
    labels = {
      app = "example"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "example"
      }
    }

    template {
      metadata {
        labels = {
          app = "example"
        }
      }

      spec {
        container {
          name  = "example-app"
          image = "gcr.io/<YOUR_PROJECT_ID>/example-app:latest"  # Replace with your own image

          ports {
            container_port = 8080
          }
        }
      }
    }
  }
}

# 8. Create a Kubernetes service to expose the app
resource "kubernetes_service" "app" {
  metadata {
    name      = "example-app-service"
    namespace = kubernetes_namespace.default.metadata[0].name
  }

  spec {
    selector = {
      app = "example"
    }

    ports {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}
