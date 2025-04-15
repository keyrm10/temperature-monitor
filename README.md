# Temperature Monitor

## 1. Project overview

**Temperature Monitor** is a cloud-ready, containerized monitoring stack that collects real-time temperature data for a specific location (default: Tallinn) using the Open-Meteo API. The data is exported as Prometheus metrics and visualized in Grafana dashboards. The project is designed for easy deployment both locally (via Docker Compose) and on Microsoft Azure (via Terraform), making it suitable for personal, educational, or demonstration purposes.

### Key features

- Periodically fetches current temperature from Open-Meteo API.
- Exposes temperature as a Prometheus metric via a custom Go exporter.
- Pre-configured Prometheus and Grafana services for monitoring and visualization.
- Infrastructure-as-Code for Azure VM deployment using Terraform.
- Secure handling of Azure credentials with SOPS and Age encryption.
- Ready-to-use Grafana dashboard for temperature visualization.

### Directory structure

```
./temperature-monitor
├── .gitignore
├── LICENSE
├── README.md
├── compose.yaml
├── grafana/
│   ├── provisioning/
│   │   ├── dashboards/
│   │   │   ├── dashboard.yaml
│   │   │   ├── temperature.json
│   │   ├── datasources/
│   │   │   ├── datasource.yaml
├── prometheus/
│   ├── prometheus.yaml
├── temperature-exporter/
│   ├── Dockerfile
│   ├── go.mod
│   ├── main.go
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── secrets/
│   │   ├── azure.enc.yaml
│   ├── user_data.sh
│   ├── variables.tf
└── .sops.yaml
```

- [`compose.yaml`](compose.yaml): Docker Compose stack definition.
- [`temperature-exporter/`](temperature-exporter/): Go exporter source and Dockerfile.
- [`prometheus/`](prometheus/): Prometheus configuration.
- [`grafana/`](grafana/): Grafana provisioning and dashboards.
- [`terraform/`](terraform/): Infrastructure-as-Code for Azure deployment.
- [`terraform/secrets/`](terraform/secrets/): Encrypted Azure credentials.

---

## 2. Technologies used

- **Go**: For the temperature exporter ([temperature-exporter/main.go](temperature-exporter/main.go))
- **Prometheus**: Metrics collection and storage ([prometheus/prometheus.yaml](prometheus/prometheus.yaml))
- **Grafana**: Visualization ([grafana/provisioning/dashboards/temperature.json](grafana/provisioning/dashboards/temperature.json))
- **Docker & Docker Compose**: Containerization and orchestration ([compose.yaml](compose.yaml))
- **Terraform**: Azure infrastructure provisioning ([terraform/main.tf](terraform/main.tf))
- **SOPS & Age**: Secrets management ([.sops.yaml](.sops.yaml), [terraform/secrets/azure.enc.yaml](terraform/secrets/azure.enc.yaml))

---

## 3. Requirements

### Local deployment

- [Docker](https://docs.docker.com/get-docker/) (>= 20.10)
- [Docker Compose](https://docs.docker.com/compose/) (v2 plugin or standalone)

### Cloud deployment

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.11.3)
- [SOPS](https://github.com/mozilla/sops) (for secrets decryption)
- [Age](https://github.com/FiloSottile/age) (for SOPS key management)
- Azure subscription and credentials (see Configuration)
- SSH key pair for VM authentication (see [Azure documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/linux-vm-connect))

  - The default SSH public key path is set in the Terraform variables to `~/.ssh/id_rsa.pub`. Ensure this key exists, or update the variable to point to your desired key. Azure VM support both RSA and ED25519. While password authentication is also available, it is less secure and not recommended.

---

## 4. Configuration

### Environment variables

- **Grafana admin password:** Set via `GF_SECURITY_ADMIN_PASSWORD` in [compose.yaml](compose.yaml) (default: `admin`).

### Configuration files

- **Prometheus:**
  Configuration: [prometheus/prometheus.yaml](prometheus/prometheus.yaml)

- **Grafana provisioning:**

  - Datasource: [grafana/provisioning/datasources/datasource.yaml](grafana/provisioning/datasources/datasource.yaml)
  - Dashboard: [grafana/provisioning/dashboards/temperature.json](grafana/provisioning/dashboards/temperature.json)

- **Azure secrets:**
  [terraform/secrets/azure.enc.yaml](terraform/secrets/azure.enc.yaml) (encrypted, see [Deployment](#b-cloud-deployment-azure-vm-with-terraform) for setup)

- **Terraform variables:**
  [terraform/variables.tf](terraform/variables.tf)
  Customize resource names, VM size, region, etc.

---

## 5. Deployment

### A. Local deployment (Docker Compose)

1. **Clone the repository:**

   ```sh
   git clone https://github.com/keyrm10/temperature-monitor.git
   cd temperature-monitor
   ```

2. **Build and start the stack:**

   ```sh
   docker compose up --build -d
   ```

3. **Access services:**
   - Metrics exporter: [http://localhost:8080/metrics](http://localhost:8080/metrics)
   - Prometheus: [http://localhost:9090](http://localhost:9090)
   - Grafana: [http://localhost:3000](http://localhost:3000) (default admin password: `admin`)

---

### B. Cloud deployment (Azure VM with Terraform)

1. **Prepare Azure credentials:**

   - Obtain your Azure `subscription_id`, `client_id`, `client_secret`, and `tenant_id`.
   - Create a secrets file at `terraform/secrets/azure.yaml`:
     ```yaml
     cat <<EOF > terraform/secrets/azure.yaml
     AZURE_SUBSCRIPTION_ID: "[subscription-id]"
     AZURE_CLIENT_ID: "[client-id]"
     AZURE_CLIENT_SECRET: "[client-secret]"
     AZURE_TENANT_ID: "[tenant-id]"
     EOF
     ```
   - Encrypt the secrets file with SOPS:
     ```sh
     sops encrypt --age [public_key] terraform/secrets/azure.yaml > terraform/secrets/azure.enc.yaml
     ```
     - Replace [public_key] with the Age public encryption key located in the [.sops.yaml](.sops.yaml) file.

2. **Initialize and apply Terraform:**

   ```sh
   cd terraform
   terraform init
   terraform apply
   ```

   - Confirm the plan and wait for deployment to complete.

3. **Retrieve service URLs:**
   - After deployment, Terraform outputs the public IP and URLs for Prometheus and Grafana.

---

## 6. Usage

### After deployment

- **Prometheus metrics:**
  Visit `/metrics` endpoint of the exporter ([http://localhost:8080/metrics](http://localhost:8080/metrics)) to see raw metrics.
  Additionally, Prometheus internal metrics are exposed at [http://localhost:9090/metrics](http://localhost:9090/metrics), which can be useful for monitoring its status and performance.

- **Grafana dashboard:**

  - Access Grafana at [http://localhost:3000](http://localhost:3000) (or the Azure VM public IP).
  - Login with username `admin` and the password set in the environment variable.
  - The "Temperature Dashboard" is pre-provisioned and displays the current temperature for Tallinn.

- **Customizing location:**
  To monitor a different location, modify the `coordinates` variable in [`temperature-exporter/main.go`](temperature-exporter/main.go), rebuild the Docker image, and restart the exporter container.

---

## License

MIT License. See [`LICENSE`](LICENSE) for details.
