
# Graylog Central Server Installation & Configuration Guide

This guide provides a step-by-step walkthrough for deploying the Graylog Central Server using a Git sparse checkout and Docker Compose. This method ensures an efficient footprint by downloading only the required deployment directory while retaining upstream Git tracking for seamless updates.


## Prerequisites

Before beginning the installation, ensure your host system meets the following requirements:
* **Operating System:** Linux (Ubuntu 22.04 LTS or newer recommended)
* **Docker:** Engine version 20.10+ installed and running
* **Docker Compose:** Version 2.0+ (using the `docker compose` plugin syntax)
* **Git:** Version 2.25 or newer (required for native sparse-checkout commands)
* **Network Ports:** Ensure ports `9000` (Graylog Web Interface/API) and any configured log ingestion ports (e.g., `514`, `12201`) are open on your firewall.



## Step 1: Optimized Repository Isolation (Sparse Checkout)

To avoid downloading unnecessary parts of the repository, we use a Git featureset called **Sparse Checkout** combined with a partial clone filter (`blob:none`). This downloads only the repository metadata initially and pulls down files matching our explicit folder pattern.

Run the following commands to clone the repository and switch to the target directory:
```bash
# Clone the repository structure without pulling down raw files
git clone --filter=blob:none --no-checkout https://github.com/Industry-Project-VTSSN/Central-logging-graylog.git
# Move into the newly created project folder
cd Central-logging-graylog

# Initialize the sparse-checkout system in 'cone' mode for maximum performance
git sparse-checkout init --cone

# Explicitly declare the directory you want to pull down
git sparse-checkout set central-server

# Force Git to check out the matching files to your disk
git checkout

# Navigate directly into your active deployment environment
cd central-server
```

*(Optional: You can safely rename the root `Central-logging-graylog` folder at any point if your infrastructure naming conventions require it. Internal Git tracking and Docker volumes will remain intact).*


## Step 2: Environment Configuration

Graylog requires structural environment variables to pepper stored passwords and secure the initial root admin account. We will instantiate our production configuration from the bundled `env.example` file.

### 1. Initialize the Environment File

Copy the example template file to create your active `.env` configuration file:
```bash
cp env.example .env
```

### 2. Auto-Populate Security Secrets

Run the following programmatic string manipulations (`sed`) to generate unique credentials and inject them directly into your active `.env` file.

#### Generate the Password Secret (Pepper)

Graylog requires a secure string of at least 64 characters to salt/pepper user passwords. The command below pulls 96 random alphanumeric characters from your system's kernel entropy pool (`/dev/urandom`):
```bash
sed -i "s|GRAYLOG_PASSWORD_SECRET=\"\"|GRAYLOG_PASSWORD_SECRET=\"$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 96)\"|" .env
```

#### Hash and Inject the Admin Password

Choose a strong master password for your initial Graylog login. Replace `your_secure_password_here` in the command below with your plaintext password. The command calculates the SHA-256 cryptographic hash and injects it into the configuration file:
```bash
sed -i "s|GRAYLOG_ROOT_PASSWORD_SHA2=\"\"|GRAYLOG_ROOT_PASSWORD_SHA2=\"$(echo -n 'your_secure_password_here' | shasum -a 256 | awk '{print $1}')\"|" .env
```

### 3. Verify Configuration Parameters

Confirm the variables were populated successfully without opening the file manually:
```bash
grep -E "GRAYLOG_PASSWORD_SECRET|GRAYLOG_ROOT_PASSWORD_SHA2" .env
```

Your terminal should return both variables containing your newly generated configurations.



## Step 3: Launching the Docker Containers

With the environment safely populated, you can spin up the multi-container stack (typically composed of Graylog, OpenSearch/Elasticsearch, and MongoDB).

Launch the stack in detached mode (running persistently in the background):
```bash
docker compose up -d
```

### Post-Deployment Verification

Verify that all services are initializing and running properly:
```bash
docker compose ps
```



## Step 4: Retrieving the One-Time Setup Password

On its very first start, Graylog triggers an isolated setup routine and generates a unique, one-time random password. You must extract this password from the container's standard output pipeline to log into the initialization web interface.

Follow the live logging output stream specifically for the Graylog container:
```bash
docker compose logs -f graylog
```

Look for a prominent text banner that matches the structure below:
```text
========================================================================================================

It seems you are starting Graylog for the first time. To set up a fresh install, a setup interface has
been started. You must log in to it to perform the initial configuration and continue.

Initial configuration is accessible at 0.0.0.0:9000, with username 'admin' and password 'wbDknaOjFu'.
Try clicking on [http://admin:wbDknaOjFu@0.0.0.0:9000/](http://admin:wbDknaOjFu@0.0.0.0:9000/)

========================================================================================================
```

> ⚠️ **Important Note:** These specific credentials are only shown in the logs during the very first run. Make sure to copy the random password string generated for your system (the example above uses `wbDknaOjFu`, but yours will be entirely unique). Save it securely.
> Once you have noted the password, press `CTRL + C` to safely exit the log stream without interrupting the running container.



## Step 5: Initial Setup & Certificate Provisioning

### 1. Access the Setup Portal

Open the setup UI in your preferred web browser:

* **On the Local Docker Host:** `http://localhost:9000`
* **From Another Network Device:** `http://<DOCKER_HOST_IP_OR_DNS>:9000`

### 2. Initial Authentication

Log into the interface using the parameters retrieved in Step 4:

* **Username:** `admin`
* **Password:** `<Your_Unique_One_Time_Password>`

After logging in, you will land on the **Graylog Initial Setup** portal. This portal steps you through building the internal certificate authority (CA) and registering your Graylog Data Nodes before allowing the cluster core to finish boot setup.

### 3. Configure the Certificate Authority (CA)

1. On the left-side steps wizard, navigate to and select **Configure a certificate authority**.
2. Click the **Create CA** button.
3. Keep the default recommended values:

* **Organization Name:** `Graylog CA`

> 🛡️ **Production Warning:** This Certificate Authority is exclusively used to encrypt **internal** cluster communications over TLS between the Graylog Central Server and its local database Data Nodes. It does not touch your external log forwarders or end users.
> Choosing **"Create CA"** is recommended for production to avoid massive certificate management overhead, as Graylog automatically provisions and rotates these internal backend assets. However, you **MUST** ensure your Docker storage volumes for MongoDB and Graylog are configuration-persistent and backed up. If your underlying persistent volumes are destroyed without a backup, this internal CA will be lost, breaking backend communications.

### 4. Configure Renewal Policy

1. Move to the next step: **Configure a renewal policy**.
2. Retain the default configuration values:

* **Renewal Policy:** `Automatic`
* **Certificate lifetime:** `30` `Day(s)`

3. Click **Create policy**.

### 5. Provision Certificates

1. Go to the step titled **Provision certificates for your data nodes**.
2. Select **Provision certificate and continue**.

### 6. Finalization & Resuming Startup

At the end of this flow, the overview page will display all workflow blocks as marked completed.

Click the **Resume startup** button. Graylog will now apply these cryptographic assets across the service components and transition into its fully initialized operational mode.

Once the interface reloads to display the primary Graylog Enterprise/Open dashboard at `http://<DOCKER_HOST_IP_OR_DNS>:9000`, the installation is officially complete.


## Next Steps

Congratulations! Your Graylog Central Server infrastructure is successfully installed, secure, and running in its optimized sparse-checkout environment.

To finalize your deployment and begin onboarding data, proceed to the next phase of the documentation:

➡️ **[Proceed to the Graylog Configuration Guide](./configuration_guide.md)**

### What you will configure next:
* **Log Ingestors (Inputs):** Activate secure network listeners for Syslog, Beats, and GELF protocols.
* **Storage Allocation (Index Sets):** Define enterprise retention policies, index rotation, and data lifecycles.
* **Telemetry Routing (Streams):** Set up rules to dynamically sort incoming logs based on fields and metadata.
* **Access Management (RBAC):** Onboard security personnel with distinct, granular roles instead of sharing the master root account.


<!-- 

## Upstream Repository Maintenance

Because we preserved the underlying Git framework during our sparse checkout, updating the system configurations or base images in the future is streamlined.

To update your deployment down the road, navigate to the `central-server` directory and run:
```bash
# Pull upstream repository configurations
git pull

# Rebuild containers and pull updated images
docker compose up -d --build

# Purge dangling cache images to free up host disk space
docker image prune -f
``` -->
