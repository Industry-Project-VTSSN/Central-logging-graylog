from diagrams import Diagram, Cluster
from diagrams.custom import Custom

# Importing built-in standard nodes
from diagrams.onprem.database import Mongodb
from diagrams.generic.storage import Storage
from diagrams.onprem.client import Client

# Importing built-in platform nodes for OS and Containerization
from diagrams.generic.os import Debian  
from diagrams.generic.os import Windows
from diagrams.onprem.container import Docker
from diagrams import Edge
# --- Your Custom Image Paths ---
OPEN_SEARCH_ICON = "C:\\0\\!!IndustryProject\\docs\\images\\opensearch.png"
GRAYLOG_ICON     = "C:\\0\\!!IndustryProject\\docs\\images\\graylog.png"
WINLOGBEAT_ICON  = "C:\\0\\!!IndustryProject\\docs\\images\\winlogbeat.png"

# Global fallback attributes
node_attributes = {
    "imagescale": "true",    
    "fontsize": "11",        
    "labelloc": "b",         
    "width":"1", 
    "height":"1.5", 
    "fixedsize":"true"
}

graph_attributes = {
    "splines": "spline",     
    "pad": "0.6",
    "nodesep": "1.0",        
    "ranksep": "1.5",        
    "concentrate": "false",
    "compound": "true"       
}

with Diagram(
    "architecture", 
    show=False, 
    direction="LR", 
    outformat="pdf",
    graph_attr=graph_attributes,
    node_attr=node_attributes  
):
    
    # 1. Remote Server Layer
    with Cluster("Remote Windows Server"):
        win_os = Windows( )
        sidecar = Client("Graylog Sidecar\n(Config Manager)")
        shipper = Custom("Winlogbeat\n(Collector)", WINLOGBEAT_ICON)
        
        win_os >>  sidecar >> shipper

    # 2. Host Infrastructure Layer
    with Cluster("Single Host VM (Debian Linux)"):
        # debian_os = Debian("Debian Core",width="1", height="1.7")
        
        # 3. Container Runtime Environment
        with Cluster("Docker Engine"):
            docker_runtime = Docker("Docker Daemon")
            
            graylog = Custom("Graylog\n(Port 9000)", GRAYLOG_ICON)
            opensearch = Custom("OpenSearch\n(Port 9200)", OPEN_SEARCH_ICON)
            mongodb = Mongodb("MongoDB\n(Port 27017)")
            
        # 4. Storage Persistence
        with Cluster("Host Storage Volumes"):
            gl_journal = Storage("Journal Vol")
            os_data = Storage("Indices Vol")

    # --- Connections & Flow ---
    # debian_os >> docker_runtime
    
    # The compound parameter guarantees these target the internal nodes cleanly now
    sidecar <<Edge(style="solid") >> graylog
    shipper >> graylog
    
    graylog >> opensearch
    graylog >> mongodb
    
    graylog >> gl_journal
    opensearch >> os_data