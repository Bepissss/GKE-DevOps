# TravelBooking — Full-Stack Microservices Travel Booking Platform

A cloud-native microservices-based travel booking application, deployed on Google Kubernetes Engine (GKE) with a complete DevOps lifecycle — Terraform, Helm, Jenkins CI/CD, Prometheus & Grafana monitoring, and HTTPS with Let's Encrypt.

---

## About the Project

TravelBooking is a cloud-native microservices travel application where users can search flights and hotels, make bookings, and process payments — similar to MakeMyTrip or Booking.com. The main focus of this project is to showcase a complete DevOps lifecycle on Google Cloud Platform.

🏗️ **Architecture** — The app is built using **microservices architecture** with 6 services — a React frontend and 5 Go backend services (user, search, booking, payment, notification). Data is stored in PostgreSQL with 5 separate databases (one per service), and Redis is used for caching search results.

☸️ **Kubernetes & Infrastructure** — Everything runs on **Google Kubernetes Engine (GKE)**. The GCP infrastructure (VPC, subnets, firewalls, Artifact Registry, static IP) is created using **Terraform** with state stored in Google Cloud Storage. The application is deployed using a custom **Helm chart** that creates all Kubernetes resources with one command.

⚙️ **CI/CD with Jenkins** — **Jenkins** runs inside the same GKE cluster and handles CI/CD. The 14-stage pipeline clones code from GitHub, tests services, builds and pushes Docker images to Artifact Registry, scans images with Trivy, packages the Helm chart, and deploys to GKE automatically.

📊 **Monitoring** — Set up with Prometheus, Grafana, and Alertmanager. Each service exposes metrics that Prometheus scrapes every 15 seconds. Grafana shows 6 custom dashboards, and Alertmanager fires alerts on pod failures, high CPU/memory, or HTTP errors.

🔒 **HTTPS & SSL** — Handled by cert-manager with Let's Encrypt. Free SSL certificates are issued automatically, and the Gateway terminates TLS. All HTTP traffic is permanently redirected to HTTPS, and certificates auto-renew every 60 days.



---

## Architecture Overview



## CI/CD Pipeline Flow (Jenkins)

```mermaid
flowchart LR
    subgraph PIPELINE["Jenkins Pipeline — 14 Stages"]
        direction LR
        S1["Git\nClone"]
        S2["Test\nGo Services"]
        S3["Test\nFrontend"]
        S4["Scan\nSonarQube scan codes"]
        S5["Docker\nLogin"]
        S6["Build & Push\n6 Docker Images"]
        S7["Trivy\nSecurity Scan"]
        S8["Update\nHelm Values"]
        S9["Package &\nPush Helm Chart"]
        S10["Deploy\nto GKE"]
    end

    GH["GitHub\nPrivate Repo"] --> S1
    S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7 --> S8 --> S9
    S5 -->|"Images"| AR["Artifact\nRegistry"]
    S8 -->|"Chart"| AR
    S9 -->|"helm upgrade\n--install"| GKE["GKE\nCluster"]
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | React.js 18, Tailwind CSS, Nginx |
| **Backend** | Go 1.21, Gin Framework, GORM |
| **Database** | PostgreSQL 15 (5 databases) |
| **Cache** | Redis 7 |
| **Container** | Docker (multi-stage builds) |
| **Orchestration** | Kubernetes (GKE) |
| **Kubernetes Management Platform** | Rancher |
| **Security - Vulnerability Scanner** | SonarQube, Trivy |
| **Infrastructure** | Terraform (modular) |
| **Packaging** | Helm Charts |
| **CI/CD** | Jenkins (on GKE) |
| **Monitoring** | Prometheus, Grafana, Alertmanager |
| **TLS/SSL** | cert-manager, Let's Encrypt |
| **Registry** | Google Artifact Registry |
| **Version Control** | GitHub (private) |

## Website
<img width="1916" height="1011" alt="image-3" src="https://github.com/user-attachments/assets/de131c0d-ed1f-4372-907c-851be483bf4c" />
<img width="1911" height="1010" alt="image-5" src="https://github.com/user-attachments/assets/762163f9-4524-41da-83a9-014e81d5508b" />
<img width="1912" height="1005" alt="image-6" src="https://github.com/user-attachments/assets/1eda2087-3622-4340-8b98-537fe644a1ed" />
<img width="1915" height="910" alt="image-2" src="https://github.com/user-attachments/assets/44d2ceb3-6595-44cf-a228-d36ca6b8d636" />


## Rancher
<img width="1917" height="913" alt="Screenshot 2026-09-23 160517" src="https://github.com/user-attachments/assets/65d6db4f-989f-4d43-ad04-c613c6b9db4d" />


## Jenkins CI/CD
<img width="1911" height="910" alt="image" src="https://github.com/user-attachments/assets/610e5a97-45c5-477c-b73b-515d1661b3de" />


## SonarQube
<img width="1917" height="921" alt="Screenshot 2026-09-23 151638" src="https://github.com/user-attachments/assets/6c40059c-b15d-47ee-a195-a5476fed35c0" />


## Grafana
<img width="1917" height="1017" alt="Screenshot 2026-09-24 114649" src="https://github.com/user-attachments/assets/730ce597-6d88-4569-9154-4f3d471c5894" />





