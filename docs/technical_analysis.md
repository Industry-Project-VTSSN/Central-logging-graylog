

# Technische Analyse: Centrale Logging & Security Monitoring

**Project:** vzw Vrije Technische Scholen Sint-Niklaas (VTSSN) 

**Auteurs:** Jonah & Thomas

**Datum:** Mei 2026

**Versie:** 0.1 (Concept)



## 1. Inleiding & Situering

### 1.1 Doelstelling van het project

Het doel van dit project is het ontwerpen, implementeren en documenteren van een centrale logging- en monitoringomgeving gebaseerd op het open-source platform Graylog. Binnen dit project wordt onderzocht hoe logs, gebeurtenissen en waarschuwingen afkomstig van een diverse mix aan servers en netwerkapparatuur efficiënt en centraal verzameld, geanalyseerd en gevisualiseerd kunnen worden.

Hierbij ligt de focus op de volgende kerngebieden:

* **Centrale logverzameling:** Het samenbrengen van alle datastromen op één centraal punt.


* **Visualisatie:** Het inzichtelijk maken van logs en systeemgebeurtenissen.


* **Basis security monitoring:** Het detecteren van verdachte activiteiten of beveiligingsrisico's binnen de omgeving.


* **Troubleshooting & infrastructuurmonitoring:** Het snel kunnen analyseren en oplossen van systeem- en netwerkfouten.


* **Configuratie van dashboards:** Het bouwen van visuele overzichten die direct meerwaarde bieden voor de ICT-dienst.


* **Automatische waarschuwingen:** Het opzetten van alerts en notificaties om direct te kunnen schakelen bij incidenten.


* **Integratie:** Het onderzoeken van koppelingsmogelijkheden met de reeds bestaande monitoringplatformen binnen de scholengroep.



### 1.2 Probleemstelling (Huidige situatie)

vzw Vrije Technische Scholen Sint-Niklaas (VTSSN) beheert een omvangrijke en heterogene ICT-infrastructuur die verspreid is over vier verschillende campussen op drie locaties. Binnen deze netwerken is een grote variëteit aan kritieke systemen actief, waaronder Hyper-V Windows Server-omgevingen, Linux-servers, Docker-applicaties en een diverse netwerk- en security-omgeving bestaande uit WatchGuard firewalls, OPNsense, HP, Aruba, MikroTik en Ruckus apparatuur.

Al deze verschillende systemen en netwerkcomponenten genereren dagelijks enorme hoeveelheden data, zoals Windows Event Logs en sysloggegevens. In de huidige situatie zijn al deze logs en monitoringgegevens echter volledig gefragmenteerd en verspreid over de individuele platformen en apparaten.

Dit gebrek aan centralisatie brengt de nodige operationele uitdagingen met zich mee:

* **Trage detectie:** Problemen en storingen binnen de infrastructuur worden niet altijd tijdig opgemerkt.


* **Tijdrovende troubleshooting:** Foutenanalyse en het opsporen van de oorzaak van een probleem is complex en kost de IT-dienst veel kostbare tijd.


* **Gebrek aan overzicht:** Er is geen centraal of uniform overzicht over de status en eventuele problemen van de gehele infrastructuur.


* **Moeilijke historische analyse:** Het correleren van data of het terugkijken in de tijd bij hardnekkige of terugkerende fouten verloopt moeizaam.


* **Security risico's:** Verdachte activiteiten of potentiële security-incidenten kunnen door de versnippering van data niet eenvoudig of snel geïdentificeerd worden.



Om deze knelpunten op te lossen en de IT-operatie te stroomlijnen, is de implementatie van een centraal platform noodzakelijk. In deze technische analyse wordt concreet uitgewerkt hoe een oplossing op basis van Graylog als deze centrale logging- en monitoringomgeving kan fungeren.






## 2. Analyse van de Logbronnen & Infrastructuur



Om een efficiënt centraal loggingplatform op te zetten, is het cruciaal om te begrijpen hoe de verschillende logbronnen binnen de scholengroep data genereren, welk protocol ze gebruiken en hoe deze data veilig getransporteerd kan worden naar de centrale Graylog-omgeving. De infrastructuur van vzw VTSSN valt uiteen in drie hoofdgroepen binnen de minimale scope:


### 2.1 Windows Server-omgeving & Hyper-V

De scholengroep maakt intensief gebruik van Windows Server-omgevingen die draaien op basis van de Hyper-V virtualisatierol. Deze systemen genereren bedrijfskritische informatie over gebruikersactiviteiten, systeemfouten en de status van virtuele machines.

#### 2.1.1 Log-type & Structuur

Windows-systemen slaan logs op in een binair formaat (`.evtx`). Deze logs zijn gestructureerd op basis van een uniek **Event ID** en gecategoriseerd in specifieke kanalen (channels) binnen de Windows Event Viewer:

* **Security Channel:** Bevat vitale security-informatie zoals succesvolle en mislukte inlogpogingen (bijv. Event ID `4625` voor een mislukte aanmelding).


* **System & Application Channels:** Bevatten hardwarefouten, servicestatusveranderingen en applicatiefouten die cruciaal zijn voor dagelijkse troubleshooting.


* **Hyper-V Specifieke Kanalen:** Binnen de *Applications and Services Logs* bevinden zich de specifieke Hyper-V logs (zoals `Hyper-V-VMMS` en `Hyper-V-Worker`). Deze registreren de status van virtuele machines (opstarten, afsluiten, live migrations) en eventuele fouten in de hypervisor.



### 2.1.2 Collectiemethode & Protocol

Omdat Graylog native geen binaire `.evtx`-bestanden kan inlezen via het netwerk, wordt er gebruikgemaakt van een agent-gebaseerde aanpak:

* **Graylog Sidecar & Winlogbeat:** Op de Windows Servers en Hyper-V hosts wordt de *Graylog Sidecar* service geïnstalleerd. Deze beheert de open-source logshipper *Winlogbeat*.


* **Protocol:** Winlogbeat leest de binaire Windows-events lokaal uit, converteert deze naar een gestructureerd JSON-formaat en transporteert ze via het **Beats-protocol** (over TCP, standaard poort `5044`) naar de centrale Graylog-server.
* **Service Account:** Voor de authenticatie en het uitlezen van de logs op de servers wordt het door de IT-dienst aangeleverde `svc_graylog_winlog` account geconfigureerd, dat beschikt over de noodzakelijke read-only rechten.


## 2.2 Netwerk- en Securityinfrastructuur (Firewalls)

De perimeterbeveiliging en segmentatie van de vier campussen wordt beheerd door een heterogene firewall-omgeving bestaande uit WatchGuard firewalls en OPNsense appliances. Deze apparaten genereren een constante stroom aan netwerk- en securitylogs.

### 2.2.1 Log-type & Structuur

Firewall-logs zijn inherent ongestructureerd of semi-gestructureerd. Ze bevatten onbewerkte tekstregels (strings) die cruciale netwerkinformatie bevatten, zoals:

* Bron- en doel-IP-adressen (Source/Destination IP).
* Gebruikte netwerkpoorten en protocollen (TCP/UDP/ICMP).
* Acties ondernomen door de firewall (Allow, Deny, Drop, Block).
* Intrusion Detection (IDS/IPS) meldingen en VPN-tunnel statuswijzigingen.



### 2.2.2 Collectiemethode & Protocol

Firewalls zijn gesloten appliances waarop geen externe software of agents (zoals Sidecar) geïnstalleerd kunnen worden. De collectie verloopt daarom volledig **agentless**:

* **Protocol:** Er wordt gebruikgemaakt van het universele **Syslog-protocol** (volgens de RFC 3164 of RFC 5424 standaard).
* **Collectiemethode:** De WatchGuard en OPNsense firewalls worden via hun eigen beheerinterface geconfigureerd om hun logbestanden in real-time over het netwerk te 'streamen' naar het IP-adres van de centrale Graylog-server. Dit gebeurt doorgaans via **UDP poort 514** (of een aangepaste poort zoals `1514` om conflicten te vermijden).
* **Verwerking in Graylog:** Omdat deze logs binnenkomen als één lange tekstregel, zal Graylog in een latere fase (via pipelines en grok-patterns) deze strings moeten opknippen in bruikbare databasevelden (bijv. `source_ip`, `action`).


## 2.3 Netwerkapparatuur (Switches & Routers)

De interne netwerkinfrastructuur op en tussen de locaties bestaat uit componenten van HP, Aruba, MikroTik en Ruckus. Het monitoren van deze switches en routers is essentieel voor het tijdig opmerken van hardwaredefecten en netwerktopologie-wijzigingen.

### 2.3.1 Log-type & Structuur

Netwerkapparatuur levert gegevens aan via twee verschillende mechanismen om zowel historische gebeurtenissen als proactieve statuswijzigingen op te vangen:

1. **Syslog-data:** Tekstgebaseerde meldingen over gebeurtenissen die al hebben plaatsgevonden (bijv. een administrator die inlogt op de switch-CLI, of een configuratiewijziging).


2. **SNMP Traps:** Asynchrone waarschuwingen die door de hardware *direct* worden verstuurd op het moment dat een specifieke drempelwaarde wordt overschreden of een kritiek event plaatsvindt (bijv. een netwerkpoort die 'down' gaat, een oververhitting van de switch, of een te hoge CPU-belasting). SNMP-data is opgebouwd rondom **OIDs (Object Identifiers)** die vertaald moeten worden aan de hand van MIB-bestanden.



### 2.3.2 Collectiemethode & Protocol

Net als bij de firewalls is de integratie van de netwerkapparatuur volledig **agentless** en gebaseerd op industriestandaarden:

* **Syslog Transport:** De HP, Aruba, MikroTik en Ruckus apparaten worden geconfigureerd om hun standaard syslog-output te sturen naar een Syslog UDP-input op de Graylog-server.


* **SNMP Transport:** Voor de SNMP-traps wordt het **SNMPv2c of SNMPv3 protocol** gebruikt. De switches worden ingesteld om hun traps te sturen naar **UDP poort 162** op de Graylog-server. Graylog activeert hiervoor een specifieke *SNMP Input plugin* die in staat is om de binnenkomende OID-structuren op te vangen en te loggen.


### 2.4 Linux-omgeving & Docker-containers

Naast de Windows-gebaseerde infrastructuur maken ook diverse Linux-servers en Docker-gebaseerde toepassingen deel uit van de kritieke omgeving binnen vzw VTSSN. Het centraal consolideren van deze logstromen is essentieel voor een integraal security- en troubleshootingoverzicht.



#### 2.4.1 Linux Systeemlogging (Graylog Sidecar & Filebeat)

Om uniformiteit te garanderen met de Windows-omgeving, wordt op de Linux-servers (zoals Ubuntu Server of Debian) de **Graylog Sidecar** service geïnstalleerd met de **Filebeat** logshipper.
* **Collectiemethode:** In plaats van te vertrouwen op traditionele, decentrale rsyslog-configuraties, leest Filebeat lokaal de Linux-systeemlogs (zoals `/var/log/auth.log` en `/var/log/syslog`) en applicatielogs uit.
* **Protocol & Beveiliging:** Het transport van de data tussen de campussen verloopt via het efficiënte en gecomprimeerde **Beats-protocol**. Dit verkeer wordt volledig versleuteld met behulp van **TLS (Transport Layer Security)** via een specifieke Beats-input op de centrale Graylog-server.
* **Beheer:** De configuratie van Filebeat wordt centraal aangestuurd vanuit de Graylog webinterface, wat het lifecycle management voor de ICT-dienst aanzienlijk vereenvoudigt.



#### 2.4.2 Docker Container Logging

Voor de gecontaineriseerde applicaties binnen VTSSN is een gestandaardiseerde logstrategie noodzakelijk, aangezien applicatielogs binnen containers standaard vluchtig (*ephemeral*) zijn en verdwijnen zodra een container herstart of wordt verwijderd.

Om dit op te vangen, worden twee scenario's ondersteund binnen de architectuur:

1. **De GELF Log Driver (Aanbevolen voor centrale applicaties):**
Docker beschikt over een native **Graylog Extended Log Format (GELF)** logging driver. Door de Docker-daemon of specifieke containers (via *Docker Compose*) te configureren met de `gelf`-driver, worden `stdout` en `stderr` stromen direct gestructureerd in JSON-formaat naar een Graylog GELF UDP/TCP input gestuurd. Dit minimaliseert de parsing-overhead in Graylog, omdat metadata zoals de *Container ID*, *Image Name* en *Command* automatisch als aparte velden worden meegeleverd.
2. **Filebeat / Graylog Sidecar (Voor specifieke applicatielogs):**
Indien een applicatie binnen een container logs naar specifieke bestanden schrijft (bijvoorbeeld een Nginx-toegangskaart in een *named volume*), kan de **Graylog Sidecar met Filebeat** op de Docker-host worden ingezet. Filebeat monitort in dat geval de logbestanden op de host die gekoppeld zijn aan de persistente volumes van de containers en stuurt deze door naar de centrale architectuur.

#### 2.4.3 Security- en Troubleshootingwaarde

Door de integratie van deze bronnen worden kritieke security-events direct inzichtelijk op de dashboards:

* **Foutieve SSH-inlogpogingen (`auth.log`):** Directe detectie van mogelijke brute-force aanvallen op Linux-servers.
* **Applicatiefouten (Docker `stderr`):** Snelle troubleshooting bij het crashen of falen van interne schooltoepassingen.
* **Privilege escalation (`sudo`):** Monitoring van beheerdersacties op het Linux-platform.



## 2.5 Samenvatting Logbronnen en Protocollen

| Bron Type | Componenten | Protocol / Agent | Standaard Poort | Type Data |
| --- | --- | --- | --- | --- |
| **Servers & Hyper-V (Windows)** | Windows Server, Hyper-V Hosts | Graylog Sidecar + Winlogbeat | `5044` (TCP) | Gestructureerd (JSON / Event ID) |
| **Servers (Linux)** | Ubuntu Server, Debian | Graylog Sidecar + Filebeat | `5044` (TCP over TLS) | Gestructureerd / Tekst (Beats-format) |
| **Applicaties (Docker)** | Gecontaineriseerde applicaties | Docker GELF Logging Driver | `12201` (UDP / TCP) | Gestructureerd (JSON) |
| **Firewalls** | WatchGuard, OPNsense | Syslog (Agentless) | `514`, `1514` of `6514` (UDP/TLS) | Semi-gestructureerd (Tekst / Strings) |
| **Netwerk (Syslog)** | HP, Aruba, MikroTik, Ruckus | Syslog (Agentless) | `514` of `1514` (UDP) | Ongestructureerd (Tekst) |
| **Netwerk (Traps)** | HP, Aruba, MikroTik, Ruckus | SNMP Traps (Agentless) | `162` (UDP) | Gestructureerd (OIDs) |







# 3. Evaluatie van de Centrale Architectuur

Om een betrouwbare en schaalbare loggingomgeving te realiseren, is een goed doordachte centrale architectuur noodzakelijk. Graylog werkt niet als een op zichzelf staand programma, maar is afhankelijk van een hechte samenwerking tussen drie kerncomponenten (de "Graylog Stack"). In dit hoofdstuk worden deze componenten geëvalueerd en wordt de deployment-strategie bepaald.



## 3.1 Graylog Stack Componenten

De centrale architectuur rust op drie softwarecomponenten die elk een specifieke taak vervullen in de verwerking, opslag en het beheer van loggegevens:

```
   [ Logbronnen: Beats / Syslog / SNMP ]
                     │
                     ▼
         ┌───────────────────────┐
         │    Graylog Server     │ ◄─── [ MongoDB ] (Metadata & Config)
         └───────────────────────┘
                     │
                     ▼
     ┌───────────────────────────────┐
     │  OpenSearch / Elasticsearch   │ (Logopslag & Indexering)
     └───────────────────────────────┘

```

### 3.1.1 Graylog Server (De Processing Engine)

De Graylog Server vormt het centrale zenuwstelsel van de opzet. Het is de actieve applicatie die verantwoordelijk is voor:

* **Ingestion:** Het openzetten van netwerkpoorten (Inputs) om data van Windows-servers, firewalls en switches op te vangen.


* **Processing & Parsing:** Het filteren en structureren van binnenkomende onbewerkte logs via extractors en pipelines om data bruikbaar te maken.
* **Routing:** Het categoriseren van logs in specifieke 'Streams' (bijvoorbeeld een aparte stroom voor alle firewall-blokkades).
* **Alerting & Web interface:** Het bewaken van drempelwaarden om automatische waarschuwingen te triggeren , en het serveren van de grafische webinterface waarin de ICT-dienst dashboards kan raadplegen.



### 3.1.2 OpenSearch of Elasticsearch (De Data Store)

Aangezien Graylog zelf geen logbestanden op de harde schijf opslaat, is een krachtige, gedistribueerde zoekmachine noodzakelijk. De scholengroep kan hier kiezen tussen *Elasticsearch* of de open-source fork *OpenSearch*. Dit component verzorgt:

* **Indexering:** Het razendsnel opslaan en indexeren van miljoenen logregels.
* **Querying:** Het in milliseconden uitvoeren van complexe zoekopdrachten wanneer een IT-beheerder historische analyses uitvoert of dashboards laadt.

* **Schaalbaarheid:** Het opvangen van de hoge performantie-eisen (Sizing) door data op te splitsen in 'shards' en index-sets.



### 3.1.3 MongoDB (De Metadata Database)

MongoDB is een NoSQL-database die uitsluitend door Graylog wordt gebruikt voor het opslaan van configuratie- en metagegevens. Er worden **geen** actieve logbestanden in opgeslagen. MongoDB bewaart onder andere:

* Gebruikersaccounts, rollen en rechten (RBAC).
* Definities en lay-outs van dashboards en widgets.
* Configuratie-instellingen van inputs, streams, pipelines en alert-regels.

## 3.2 Deployment Strategie

Voor de inrichting van de centrale loggingomgeving binnen de infrastructuur van vzw VTSSN zijn er drie mogelijke deployment-methoden geëvalueerd: Virtual Machines (traditioneel), Docker Containers (modern), of een Hybride aanpak.

### 3.2.1 Vergelijking van Deployment-methoden

| Criterium | Virtual Machines (Bare-OS) | Docker Containers | Hybride Aanpak |
| --- | --- | --- | --- |
| **Performantie** | Maximaal (Directe toegang tot CPU/RAM/Storage) | Zeer hoog (Minimale overhead van de Docker-engine) | Hoog (VM voor storage, Containers voor apps) |
| **Complexiteit Installatie** | Hoog (Elk component moet handmatig geïnstalleerd en gelinkt worden) | Laag (Volledige stack start op met één `docker-compose` script) | Medium (Complex netwerkbeheer tussen VM's en containers) |
| **Onderhoud & Updates** | Tijdrovend (Losse package-updates per VM en OS-updates) | Zeer eenvoudig (Containers weggooien en met een nieuwe image opstarten) | Medium (Gedeeld onderhoud van OS en container-engines) |
| **Resource-footprint** | Hoog (Elke VM heeft een eigen OS-overhead voor RAM en diskruimte) | Minimaal (Componenten delen de resources van de onderliggende host) | Medium (Meerdere OS-lagen vereist) |
| **Back-up & Disaster Recovery** | Eenvoudig via Hyper-V checkpoints/back-ups | Eenvoudig door het back-uppen van persistent gemonteerde data-volumes | Medium (Verschillende back-up-strategieën combineren) |

### 3.2.2 Verantwoording Gekozen Aanpak: Docker Containers

Voor dit project wordt gekozen voor een **Docker-gebaseerde deployment** op een Linux-host (of via een Linux VM binnen de Hyper-V omgeving).

**Argumentatie voor deze keuze:**

1. **Snelheid en Reproduceerbaarheid:** De volledige Graylog-stack (Graylog, OpenSearch en MongoDB) kan via een enkel `docker-compose.yml` bestand consistent en foutloos worden uitgerold. Dit versnelt het opzetten van de testomgeving aanzienlijk en vereenvoudigt de *Installatiehandleiding* voor de ICT-dienst.


2. **Resource-efficiëntie op de Campus:** Omdat de scholengroep al over een uitgebreide infrastructuur beschikt, voorkomt containerisatie onnodige "VM-wildgroei" (VM-sprawl). De drie stack-componenten draaien geïsoleerd op één enkele Linux-omgeving zonder de overhead van drie aparte operating systemen.


3. **Eenvoudig Lifecycle Management:** Updates van OpenSearch of Graylog kunnen in de toekomst door de IT-dienst worden uitgevoerd door simpelweg het versienummer in het configuratiebestand aan te passen en de containers te herstarten.


4. **Isolatie van Data:** Door gebruik te maken van Docker *named volumes* wordt de database-opslag van OpenSearch strikt gescheiden van de applicatielogica, wat voordelen biedt voor de back-up-strategie en opslag-performantieanalyse.


# 4. Beantwoording van de Kernvragen

Binnen dit project heeft de scholengroep een aantal gerichte vragen geformuleerd om de efficiëntie, meerwaarde en schaalbaarheid van de nieuwe centrale loggingomgeving te waarborgen. In dit hoofdstuk worden deze kernvragen technisch geanalyseerd en beantwoord op basis van de Graylog-architectuur.



## 4.1 Hoe kunnen logs efficiënt gecentraliseerd en geanalyseerd worden? 

Efficiënte centralisatie en analyse vallen of staan met het scheiden van transport, structurering en routering. Om te voorkomen dat het netwerk van de scholengroep overbelast raakt en de IT-dienst verdrinkt in ongestructureerde data, hanteert Graylog een gestroomlijnd proces:

### 4.1.1 Efficiënte Centralisatie (Transport & Ingest)

* **Lightweight Shippers:** Voor Windows-omgevingen wordt gebruikgemaakt van Winlogbeat via de Graylog Sidecar. Winlogbeat heeft een minimale resource-footprint (CPU/RAM) en verstuur logs gecomprimeerd via het Beats-protocol naar de server, wat WAN-verkeer tussen de campussen minimaliseert.


* **Agentless Netwerkstreams:** Firewalls en switches pushen hun logs via Syslog direct over UDP naar de server. UDP kent minder overhead dan TCP, wat de netwerkimpact op core-switches minimaliseert.



### 4.1.2 Efficiënte Analyse (Parsing & Pipelines)

Onbewerkte tekstlogs (zoals syslog van OPNsense of WatchGuard) zijn voor een mens moeilijk doorzoekbaar. Graylog analyseert en structureert deze logs efficiënt via:

* **Extractors & Grok Patterns:** Met behulp van Regular Expressions (RegEx) en voorgedefinieerde Grok-patronen filtert Graylog variabelen uit tekstregels. Een ongestructureerde firewall-log wordt automatisch opgeknipt in duidelijke databasevelden zoals `source_ip`, `destination_port` en `action`.
* **Processing Pipelines:** Dit zijn opeenvolgende regels (rules) waarmee data verrijkt of gemanipuleerd kan worden. Zo kan een pipeline een IP-adres matchen aan een geografische locatie (GeoIP-lookup) of bekende kwaadaardige IP-lijsten (Threat Intelligence Integration), zodat kwaadaardig verkeer direct oplicht in de zoekresultaten.





## 4.2 Welke dashboards bieden de meeste meerwaarde voor de ICT-dienst? 

Om de huidige versnippering en het gebrek aan centraal overzicht tegen te gaan, moet de ICT-dienst in één oogopslag de gezondheid en veiligheid van de vier campussen kunnen aflezen. De volgende drie dashboards bieden de grootste operationele meerwaarde:

### 4.2.1 Dashboard 1: Netwerk Security & Firewall Overzicht

* **Doel:** Direct inzicht in perimeter-dreigingen en netwerkactiviteit.
* **Kern-widgets:**  Grafiek met het aantal geblokkeerde verbindingspogingen per campus (WatchGuard/OPNsense).
* Top 10 bron-IP-adressen die geblokkeerd worden (detectie van brute-force of poortscans).
* Actieve VPN-tunnels en bandbreedte-pieken per locatie.





### 4.2.2 Dashboard 2: Windows & Hyper-V Infrastructuur Status

* **Doel:** Snelle foutanalyse en capaciteitsbeheer van de serveromgeving.
* **Kern-widgets:** Tijdlijn met kritieke Windows Event Fouten (Event ID `4625` - Mislukte aanmeldingen).
* Hyper-V statuswijzigingen (VM's die onverwacht stoppen of migreren).
* Systeemwaarschuwingen (bijv. diskruimte-tekort of mislukte back-up services).



### 4.2.3 Dashboard 3: Network Health (SNMP)

* **Doel:** Proactieve monitoring van switches en routers.


* **Kern-widgets:** Overzicht van switchpoorten die 'Down' of 'Up' gaan via SNMP traps.


* Hardware-status (CPU-belasting, geheugengebruik en temperatuur van HP/Aruba/MikroTik core-switches).




## 4.3 Hoe kunnen automatische waarschuwingen bijdragen aan sneller incidentbeheer?

Binnen de huidige infrastructuur van de scholengroep worden problemen niet altijd snel gedetecteerd omdat logs verspreid zijn en handmatig gecontroleerd moeten worden. Het handmatig doorspitten van gigantische logbestanden tijdens een incident is tijdrovend. Automatische waarschuwingen (Alerts) binnen Graylog lossen dit op door monitoring te transformeren van **reactief** (zoeken naar de oorzaak als het systeem al plat ligt) naar **proactief** (direct signaleren wanneer een drempelwaarde wordt overschreden).

### 4.3.1 Mechanismen voor snellere incidentdetectie

Automatische waarschuwingen dragen op de volgende manieren bij aan een versneld incidentbeheer:

* **Real-time Event Filteren:** Graylog scant binnenkomende logstromen (zoals Syslog en Beats) in real-time. Zodra een logregel aan vooraf gedefinieerde criteria voldoet (bijvoorbeeld een `Critical` of `Emergency` statuscode van een OPNsense firewall), wordt er direct een alarm gegenereerd.


* **Drempelwaarde-bewaking (Thresholds):** In plaats van te reageren op een enkele fout, kan Graylog patronen herkennen. Als een Aruba- of HP-switch binnen 1 minuut meer dan 50 SNMP-traps verstuurt over poortfouten (packet loss), activeert Graylog een waarschuwing. Dit voorkomt dat de ICT-dienst overspoeld wordt met losse meldingen, maar wel direct ingrijpt bij escalaties.


* **Security Correlatie:** Verdachte activiteiten, zoals brute-force inlogpogingen op Windows-servers of Hyper-V hosts, kunnen direct worden blootgelegd. Een alert kan zo worden ingesteld dat deze afgaat wanneer er binnen 5 minuten meer dan 15 mislukte inlogpogingen (Event ID `4625`) worden geregistreerd.



### 4.3.2 Directe Notificatiekanalen

Om de reactietijd van de ICT-dienst te minimaliseren, koppelt Graylog waarschuwingen aan automatische notificaties. Hierdoor hoeft de IT-beheerder niet constant naar het Graylog-dashboard te kijken:

* **E-mailnotificaties:** Kritieke serverfouten of schijfruimte-waarschuwingen kunnen direct naar het ticketsysteem of de mailbox van de IT-dienst worden gemaild.
* **Webhooks (bijv. Microsoft Teams):** Bij dringende infrastructurele problemen of security-incidenten kan Graylog via een webhook een direct bericht pushen in het Teams-kanaal van de netwerkbeheerders, inclusief relevante details zoals de hostnaam en de exacte foutmelding.



## 4.4 Welke retention policies zijn geschikt voor de scholengroep?

Een *retention policy* (bewaartermijnbeleid) bepaalt hoe lang loggegevens bewaard blijven en wanneer oude gegevens automatisch worden verwijderd of gearchiveerd. Voor vzw VTSSN is het belangrijk om een balans te vinden tussen historische analyse (onderzoek naar incidenten uit het verleden) en de beschikbare opslagcapaciteit en performantie van de monitoringservers.

Omdat de scholengroep beschikt over vier campussen met een grote hoeveelheid netwerk- en serverapparatuur, is een **gelaagde retentiestrategie** het meest geschikt:

### 4.4.1 Hot Storage (Direct doorzoekbaar): 30 dagen

* **Toepassing:** Alle binnenkomende Windows Event Logs, firewall syslog-data en SNMP traps worden opgeslagen in actieve indexen binnen OpenSearch/Elasticsearch.


* **Kenmerken:** De data is volledig geïndexeerd en direct binnen enkele milliseconden doorzoekbaar via de Graylog-webinterface en dashboards.


* **Verantwoording:** Uit de probleemstelling blijkt dat troubleshooting momenteel complex en tijdrovend is. 30 dagen direct doorzoekbare data is ruim voldoende voor dagelijkse foutanalyses, het oplossen van actuele netwerkproblemen en het controleren van recente security-meldingen.



### 4.4.2 Warm Storage / Archief (Gecomprimeerd): 90 tot 180 dagen

* **Toepassing:** Zodra logs ouder zijn dan 30 dagen, worden de indexen automatisch door Graylog gesloten (Index Rotation).


* **Kenmerken:** De data wordt uit het actieve, dure RAM-geheugen van de database gehaald, gecomprimeerd tot platte bestanden en verplaatst naar goedkopere opslag (bijvoorbeeld een dedicated partitie of netwerkschijf binnen de scholengroep). De data is niet meer direct via dashboards zichtbaar, maar kan bij een historisch (security-)onderzoek binnen enkele minuten worden teruggezet (geïmporteerd).


* **Verantwoording:** Dit lost de noodzaak voor historische analyse op zonder dat de centrale database (OpenSearch) traag wordt of vastloopt door een overschot aan data.



### 4.4.3 Definitieve Verwijdering (Purge): Na 180 dagen

* **Toepassing:** Logs die de maximale bewaartermijn van bijvoorbeeld een half jaar hebben overschreden, worden automatisch en definitief van de harde schijf gewist.
* **Verantwoording:** Dit beschermt de schaalbaarheid van de opslagomgeving en zorgt ervoor dat de scholengroep voldoet aan de wetgeving rondom dataminimalisatie en privacy (GDPR), aangezien logs gebruikersnamen of IP-adressen van studenten en medewerkers kunnen bevatten.

## 4.5 Welke impact hebben logretentie en opslag op performantie en schaalbaarheid? 

Logbestanden kunnen exponentieel groeien, zeker in een omgeving met vier campussen en honderden netwerkcomponenten. Dit heeft directe gevolgen voor de systeemperformantie:

* **I/O-Performance (Schrijfsnelheid):** OpenSearch/Elasticsearch voert bij elke binnenkomende logregel schrijf- en indexeeracties uit. Als de schijven (bij voorkeur SSD/NVMe) de hoeveelheid Events Per Second (EPS) niet kunnen bijhouden, ontstaat er een wachtrij (buffer) en vertraagt het hele platform.


* **Geheugenbelasting (RAM):** De zoekmachine houdt index-structuren in het RAM-geheugen om snelle zoekresultaten te garanderen. Hoe meer data en hoe groter de retentieperiode, hoe meer RAM OpenSearch vereist. Te weinig RAM leidt tot trage dashboards en timeouts.


* **Schaalbaarheid via Index Sets:** Om de performantie hoog te houden, deelt Graylog data op in *Index Sets* met een rotatiestrategie (bijv. roteer index zodra deze 20 GB groot is, of elke 7 dagen). Hierdoor hoeft de zoekmachine nooit in één gigantisch bestand te zoeken, wat de schaalbaarheid optimaliseert bij groei van de scholengroep.




## 4.6 Hoe kunnen bestaande monitoringplatformen geïntegreerd worden binnen een centrale loggingomgeving? 

Graylog focust op *logs* (gebeurtenissen uit het verleden), terwijl platformen zoals Zabbix of Prometheus focussen op *metrieken* (real-time status zoals CPU % of uptime). Integratie biedt een compleet 360-graden overzicht:

* **Zabbix Integratie:** Zabbix kan via API-koppelingen of scripts alerts doorsturen naar Graylog wanneer een server offline gaat. Omgekeerd kan Graylog een alert triggeren (bijv. "Firewall CPU > 90% op basis van syslog") en dit als een event inschieten in Zabbix, zodat de IT-dienst één centraal dashboard behoudt voor incidenten.


* **Grafana Integratie:** Grafana kan OpenSearch/Elasticsearch rechtstreeks als databron (Data Source) aanspreken. Hierdoor kan de ICT-dienst de rijke logdata uit Graylog combineren met metrieken uit Prometheus of Zabbix in één overkoepelend, esthetisch Grafana-dashboard.





# 5. Security & Privacy Overwegingen

Centrale logbestanden bevatten een schat aan gevoelige informatie over de IT-infrastructuur, netwerkstromen en gebruikersactiviteiten van vzw VTSSN. Het beveiligen van deze centrale loggingomgeving en het respecteren van de privacywetgeving is daarom een kritisch onderdeel van dit project. Hieronder wordt beschreven hoe security en privacy gewaarborgd worden binnen de voorgestelde Graylog-architectuur.

## 5.1 Data-encryptie (Security in Transit & Rest)

Logs mogen tijdens het transport over het netwerk tussen de campussen niet leesbaar zijn voor onbevoegden, en moeten ook op de centrale server veilig worden opgeslagen.

* **Beveiliging van Beats-verkeer (Windows/Hyper-V):** Het transport van Windows Event Logs via Winlogbeat naar de Graylog-server kan volledig worden versleuteld met behulp van **TLS (Transport Layer Security)**. Hierbij wordt een TLS-certificaat op de Graylog-input geïnstalleerd, waardoor de Sidecar-agents de data via een beveiligde, versleutelde TCP-verbinding versturen.
* **Beveiliging van Syslog-verkeer (Firewalls & Switches):** Traditioneel Syslog-verkeer over UDP (poort 514) is onversleuteld. Waar mogelijk (bijvoorbeeld bij moderne firewalls zoals OPNsense of WatchGuard) kan worden overgestapt op **Syslog over TLS (TCP poort 6514)**. Voor legacy switches die dit niet ondersteunen, moet worden gewaarborgd dat dit onversleutelde verkeer uitsluitend binnen een afgeschermd en beveiligd beheer-VLAN (Management VLAN) getransporteerd wordt.
* **Encryption at Rest:** De onderliggende database (OpenSearch/Elasticsearch) kan zo geconfigureerd worden dat de opgeslagen indexbestanden op de harde schijf (of Docker storage volumes) versleuteld zijn. Dit voorkomt dat logs direct leesbaar zijn als de fysieke of virtuele schijven in verkeerde handen vallen.



## 5.2 Toegangsbeheer (Role-Based Access Control - RBAC)

Niet elke medewerker binnen de scholengroep hoeft toegang te hebben tot alle logbestanden. Graylog beschikt over een ingebouwd RBAC-systeem waarmee rollen en rechten strikt gescheiden kunnen worden:

* **Strikte scheiding van rollen:**  **Beheerders (Administrators):** Hebben volledige rechten over het platform. Zij kunnen inputs configureren, indexen beheren en pipelines aanmaken.
* **ICT-Support / Helpdesk:** Krijgen een rol met beperkte rechten (Read-Only). Zij kunnen uitsluitend specifieke dashboards inzien en logs doorzoeken voor troubleshooting (bijvoorbeeld kijken waarom een account van een leerkracht geblokkeerd is), maar kunnen geen configuratiewijzigingen doorvoeren.


* **Gekoppelde Streams en Dashboards:** Rechten kunnen in Graylog per 'Stream' worden toegekend. Zo kan de netwerkbeheerder exclusief toegang krijgen tot de WatchGuard en OPNsense firewall-streams, terwijl een systeembeheerder alleen toegang krijgt tot de Windows Server-logs.



## 5.3 Privacy & Algemene Verordening Gegevensbescherming (GDPR)

Aangezien de scholengroep persoonsgegevens verwerkt van zowel studenten als leerkrachten, moeten de verzamelde logs voldoen aan de GDPR-wetgeving. Systeemlogs bevatten immers vaak herleidbare persoonsgegevens, zoals gebruikersnamen (`vtssn\voornaam.achternaam`) en IP-adressen.

* **Dataminimalisatie:** Er worden uitsluitend logs verzameld die noodzakelijk zijn voor troubleshooting, infrastructuurmonitoring en basis security monitoring. Logs van applicaties die puur persoonlijke of niet-relevante data bevatten, worden op voorhand uitgesloten van centralisatie.
* **Anonymisering en Pseudonimisering via Pipelines:** Indien de wetgeving of het interne beleid dit vereist, kunnen Graylog processing pipelines worden ingezet om gevoelige velden te maskeren. Zo kan het laatste octet van een IP-adres van een studenten-device automatisch worden geanonimiseerd (bijv. `192.168.10.45` wordt `192.168.10.0`), of kunnen specifieke privacygevoelige strings uit de logtekst worden gefilterd voordat ze geïndexeerd worden in OpenSearch.
* **Geautomatiseerde Retentie als Privacywaarborg:** Zoals vastgelegd in de *retention policies*, worden logs na een vooraf gedefinieerde termijn (bijvoorbeeld 30 dagen hot en maximaal 180 dagen in archief) definitief en onherroepelijk gewist. Dit zorgt ervoor dat data niet langer dan noodzakelijk bewaard blijft, wat een harde eis is binnen de GDPR.
* **Audit Logging binnen Graylog:** Graylog houdt zelf een intern logboek (Internal Audit Log) bij. Hierin wordt exact geregistreerd welke IT-beheerder op welk moment welke zoekopdracht heeft uitgevoerd. Dit voorkomt misbruik van het platform en garandeert dat het inzien van logs altijd traceerbaar is.




# 6. Conclusie
In dit afsluitende hoofdstuk wordt de voorgestelde architectuur samengevat en gewaardeerd op basis van de projectdoelstellingen.
## 6.1 Conclusie van de voorgestelde architectuur

De huidige versnippering van logs en monitoringgegevens over verschillende platformen binnen vzw VTSSN maakt troubleshooting complex en vertraagt de detectie van netwerk- en security-incidenten. Met de inrichting van een centraal Graylog-platform wordt een robuuste, schaalbare en toekomstbestendige oplossing voorgesteld om deze operationele knelpunten efficiënt op te lossen.

De gekozen architectuur rust op een Docker-gebaseerde deployment van de centraliserende Graylog-stack. Deze opzet minimaliseert de resource-footprint op de campus en garandeert een snelle en reproduceerbare uitrol via containerisatie. Door een gelaagde aanpak te hanteren—waarbij Windows- en Hyper-V hosts via een lichtgewicht Graylog Sidecar (Winlogbeat) worden uitgelezen, en netwerkcomponenten en firewalls agentless via Syslog en SNMP traps communiceren—wordt de impact op de bandbreedte tussen de vier campussen tot een minimum beperkt.

Dankzij de gedefinieerde retentieperioden (30 dagen hot storage en tot 180 dagen gecomprimeerd archief), de implementatie van Role-Based Access Control (RBAC) en data-encryptie via TLS, voldoet het platform volledig aan de wetgeving rondom dataminimalisatie en privacy (GDPR), zonder in te boeten op de vereiste historische analysecapaciteit van de ICT-dienst.
