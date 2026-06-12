from diagrams import Diagram, Cluster
from diagrams.onprem.client import Client
from diagrams.onprem.container import Docker
from diagrams.onprem.database import Mongodb
from diagrams.onprem.search import Solr  
from diagrams.onprem.logging import Fluentbit 
from diagrams.generic.storage import Storage
from diagrams.custom import Custom


OPEN_SEARCH_ICON =  "C:\\0\\!!IndustryProject\\docs\\images\\opensearch.png"
GRAYLOG_ICON = "C:\\0\\!!IndustryProject\\docs\\images\\graylog.png"
WINLOGBEAT_ICON = "C:\\0\\!!IndustryProject\\docs\\images\\winlogbeat.png"

graph_attributes = {
    "splines": "spline", 
    "pad": "0.5",
    "nodesep": "0.6",
    "ranksep": "0.75"
}

with Diagram(
    "architecture", 
    show=False, 
    direction="LR", 
    outformat="pdf",
    graph_attr=graph_attributes
):
    
    with Cluster("Remote Client Server"):
        shipper = Custom("Winlogbeat\n(Collector)", WINLOGBEAT_ICON)
        sidecar = Client("Graylog Sidecar\n(Config Manager)")
        sidecar >> shipper

    with Cluster("Single Host VM"):
        with Cluster("Docker Engine"):
            graylog = Custom("Graylog\n(Port 9000)", GRAYLOG_ICON)
            opensearch = Custom("OpenSearch\n(Port 9200)", OPEN_SEARCH_ICON)
            mongodb = Mongodb("MongoDB\n(Port 27017)")
            
        with Cluster("Host Storage Volumes"):
            gl_journal = Storage("Journal Vol")
            os_data = Storage("Indices Vol")

    shipper >> graylog
    graylog >> opensearch
    graylog >> mongodb
    
    graylog >> gl_journal
    opensearch >> os_data