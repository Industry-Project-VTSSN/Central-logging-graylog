# Graylog Central Server Configuration Guide

This guide covers the foundational configuration steps required immediately after a successful deployment. It details how to ingest your first streams of data, manage log storage lifecycle policies, and establish structured access controls.

---

> ⚠️ **Prerequisite:** Before proceeding with this guide, ensure you have successfully completed the [Installation & Configuration Guide](https://www.google.com/search?q=./installation_guide.md). You must have a fully functional Graylog Central Server running, your internal data node certificate authority established, and administrative web access available at `http://<DOCKER_HOST_IP_OR_DNS>:9000`.

## Interactive Input Setup Wizard Flow

This section walks through configuring a standard ingestion data stream utilizing the unified **Input Setup Wizard** in **Graylog 7.1.2**. This process provisions the network listener (**Input**), logical filter rules (**Stream**), and physical storage configurations (**Index Set**) in a single pipeline.

---
### Step 1: Initiate Input Creation


1. Authenticate to your web console and go to **System** > **Inputs** from the top global navigation bar.
2. Expand the drop-down menu on the left side of the screen and select **Beats** (or your targeted collection mechanism).
3. Click the **Launch new input** button.




---

### Step 2: Configure Core Network Parameters

Define how the Graylog server instances will bind and listen for edge payload traffic.

1. **Global Checkbox:** Leave checked to instruct Graylog to run this input daemon identically across all instances in a clustered environment.
2. **Title:** Enter a declarative naming pattern (e.g., `Global Beats TCP Listener`).
3. **Bind address:** Use `0.0.0.0` to listen on all available server network interfaces.
4. **Port:** Keep the standard protocol default `5044`.
* *Note:* Ports below `1024` require active system `CAP_NET_BIND_SERVICE` capability privileges explicitly granted to the Java runtime binary under Linux 6.12.


5. **Advanced Parameters:** Keep the default parameters for *Receive Buffer Size* (`1048576`) and *No. of worker threads* (`1`).
6.  Click **Launch Input**.




---


### Step 3: Define Stream Routing Boundaries

The setup wizard will automatically transition to the **Routing** phase to keep incoming workloads separated from common system index queues.

1. Click the **Create a new Stream** button to expand the stream generation sub-form.
2. **Title & Description:** Give the processing layer a descriptive name (e.g., `Beats Processing Stream`).
3. **Isolate Stream Traffic:** Ensure **Remove matches from "Default Stream"** is checked. This forces logs processed through this input to bypass the unorganized catch-all default workspace.
4. **Processing Pipeline:** Leave **Create a new pipeline for this stream** checked to instantly attach processing rules downstream.
5. **Index Set Target:** Review the system notification highlighting OpenSearch mapping field-limit thresholds
6. Select **Create Index Set**. **Note:** This action will automatically launch the configuration form in a **new browser tab**.



---

### Step 4: Select an Operational Storage Template

Select an indexing duration template matching your organizational storage boundaries and performance goals.

1. Under the **Built-in Templates** tab, assess the targeted lifecycle policies:
* **7 Days Hot:** Best for developer testing or low-capacity staging instances.
* **14 Days Hot:** Optimized for standard operations requiring a two-week lookup window.
* **30 Days Hot:** Recommended standard for production auditing workflows.


2. Select your targeted template option and click **Apply template**.



---


### Step 5: Finalize Index Set Details

Confirm backend search engine storage configurations and replica distributions.

1. **Title:** Set a distinct storage name (e.g., `Beats Production Storage Pool`).
2. **Description:** Enter a clear operational summary detailing the source, environment, or ownership of the logs being stored (e.g., `Stores long-term core system events from edge servers forwarders`). **Note:** This field is required to maintain traceable infrastructure documentation.
3. **Index Prefix:** Input a lowercase, alphanumeric-only identifier string (e.g., `beats-prod-data`). *This cannot be changed post-creation.*
4. **Index Shards:** Leave at `4` (or lower to match your physical search nodes; do not exceed your actual cluster node count).
5. **Index Replicas:** Default to `0` for single standalone sandbox deployments, or scale to `1` for active data failover protections across multi-node clusters.
6. **Rotation & Retention Window:** Verify that the timeline parameters automatically copied from your step 4 template selection match expectations.
7. Click **Create Index Set**. Once saved, **close this browser tab**



---

### Step 6: Link Index and Complete Ingestion Setup
Return to your workflow environment to tie the newly provisioned components together.

1. Switch back to your **original browser tab** containing the open *Input Setup Wizard*.
2. Scroll to the bottom of the Routing section to the **Select Index Set** dropdown menu.
3. Select your newly created Index Set from the listing.
4. Click **Next** to advance past the routing validations.
5. The wizard moves to the **Launch** stage. Click the blue **Start Input** button.
6. Finally, click the **Launch Input Diagnosis** button to verify port bindings and successfully activate the real-time telemetry line.



## Next Steps
Now that the server is listening for Beats traffic on port 5044, proceed to the [Windows Sidecar Installation & Configuration Guide](./installing_and_configuring_windows_sidecar.md) to deploy the forwarder agent onto your target endpoints.


<!-- ## Post-Configuration Verification

Verify host-level networking and engine ingestion rules using native Linux terminal utilities:

### 1. Socket Verification

Ensure that the Java process has successfully bound to your designated listening socket:

```bash
ss -tulwn | grep 5044

```

### 2. Firewall Adjustment (Debian/UFW)

Open local access parameters to let external log forwarders cleanly route data to the host:

```bash
sudo ufw allow 5044/tcp comment 'Graylog Beats Ingress Engine'
sudo ufw reload

``` -->