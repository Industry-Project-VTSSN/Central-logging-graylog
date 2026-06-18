from diagrams import Cluster, Diagram, Edge
from diagrams.custom import Custom
from diagrams.onprem.database import Mongodb
from diagrams.onprem.container import Docker
from diagrams.onprem.client import Client
from diagrams.generic.storage import Storage
from diagrams.generic.network import Router
from diagrams.generic.os import Windows

# --- Custom icon paths ---
OPEN_SEARCH_ICON = r"C:\0\!!IndustryProject\docs\images\opensearch.png"
GRAYLOG_ICON = r"C:\0\!!IndustryProject\docs\images\graylog.png"
WINLOGBEAT_ICON = r"C:\0\!!IndustryProject\docs\images\winlogbeat.png"

node_attributes = {
    "imagescale": "true",
    "fontsize": "11",
    "labelloc": "b",
    "width": "1.2",
    "height": "1.4",
    "fixedsize": "true",
}

graph_attributes = {
    "splines": "spline",
    "pad": "0.5",
    "nodesep": "0.9",
    "ranksep": "1.2",
    "concentrate": "false",
    "compound": "true",
}

with Diagram(
    "architecture_v2",
    show=False,
    direction="LR",
    outformat="pdf",
    graph_attr=graph_attributes,
    node_attr=node_attributes,
):
    # Source side: Windows/Hyper-V with WEF collector pattern
    with Cluster("Windows / Hyper-V bronnen"):
        windows_hosts = Windows("Windows & Hyper-V Hosts")
        wef_collector = Windows("WEF Collector")
        winlogbeat = Custom("Winlogbeat\n(Beats -> 5044)", WINLOGBEAT_ICON)

        windows_hosts >> Edge(label="WEF subscription") >> wef_collector
        wef_collector >> Edge(label="Read forwarded events") >> winlogbeat

    # Source side: network devices via syslog
    with Cluster("Netwerk en Security bronnen"):
        network_devices = Router("Switches/Routers")
        firewalls = Router("Firewalls")

    # Graylog platform side
    with Cluster("Centrale Graylog host (Docker)"):
        docker_runtime = Docker("Docker Engine")

        with Cluster("Ingestie en verwerking"):
            graylog = Custom("Graylog\nUI:9000\nBeats:5044\nSyslog:1514", GRAYLOG_ICON)

        with Cluster("Opslag"):
            opensearch = Custom("OpenSearch/Data Node", OPEN_SEARCH_ICON)
            mongodb = Mongodb("MongoDB")
            graylog_journal = Storage("Graylog Journal")
            index_storage = Storage("Index Storage")

        with Cluster("Consumptie"):
            dashboards = Client("Graylog Dashboards")
            alerts = Client("Alert Notificaties")

    # Ingestion edges aligned with documentation
    winlogbeat >> Edge(label="TCP 5044 (Beats)") >> graylog

    network_devices >> Edge(label="UDP 514") >> docker_runtime
    firewalls >> Edge(label="UDP 514") >> docker_runtime
    docker_runtime >> Edge(label="Forward -> UDP 1514") >> graylog

    # Internal processing and storage
    graylog >> Edge(label="Indexing") >> opensearch
    graylog >> Edge(label="Metadata") >> mongodb
    graylog >> Edge(label="Journal write") >> graylog_journal
    opensearch >> Edge(label="Persistent indices") >> index_storage

    # Consumer outputs
    graylog >> Edge(label="Streams / Queries") >> dashboards
    graylog >> Edge(label="Alert rules") >> alerts
