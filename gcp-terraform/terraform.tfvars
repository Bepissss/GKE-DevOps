
# ─── GCP Project Settings ─────────────────────────────────────────────────────
project-id       = "project-15cbfd8b-99cf-4659-9c8"   
region           = "asia-southeast1"                     
credentials-file = "./keys.json"                    

# ─── VPC & Subnet ─────────────────────────────────────────────────────────────
vpc-name    = "travelbooking-vpc"
subnet-name = "travelbooking-subnet"
vpc-cidr    = "10.0.0.0/16"

# ─── GKE Cluster ──────────────────────────────────────────────────────────────
cluster-name    = "travelbooking-gke"
cluster-zone    = "asia-southeast1-a"
cluster-version = "1.36"

# ─── GKE Node Pool ────────────────────────────────────────────────────────────
pool-name         = "travelbooking-nodepool"
node-image-type   = "COS_CONTAINERD"
node-disk-type    = "pd-standard"
node-disk-size    = 50
node-machine-type = "e2-standard-2"
node-count        = 2
min-node-count    = 2
max-node-count    = 3

# ─── Artifact Registry ────────────────────────────────────────────────────────
artifact-registry-name = "travel-booking"

# ─── Static IP ────────────────────────────────────────────────────────────────
static-ip-name = "travel-booking-ip"
