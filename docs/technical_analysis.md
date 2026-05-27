

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



## 2.4 Samenvatting Logbronnen en Protocollen

| Bron Type | Componenten | Protocol / Agent | Standaard Poort | Type Data |
| --- | --- | --- | --- | --- |
| **Servers & Hyper-V** | Windows Server, Hyper-V Hosts | Graylog Sidecar + Winlogbeat | `5044` (TCP) | Gestructureerd (JSON / Event ID) |
| **Firewalls** | WatchGuard, OPNsense | Syslog (Agentless) | `514` of `1514` (UDP) | Semi-gestructureerd (Tekst / Strings) |
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


## 4. Beantwoording van de Kernvragen

Dit is de theoretische kern van je analyse, gebaseerd op de vragen uit de projectfiche.

### 4.1 Efficiënte Centralisatie en Analyse

* Hoe worden logs gecentraliseerd zonder het netwerk te overbelasten?


* Welke rol spelen extractors, grok patterns en pipelines bij het structureren van ongestructureerde data?



### 4.2 Meerwaarde van Dashboards voor de ICT-dienst

* Welke specifieke statistieken en KPI's moeten visueel getoond worden om troubleshooting te versnellen?



### 4.3 Incidentbeheer via Automatische Waarschuwingen

* Hoe dragen alerts bij aan snellere detectie van verdachte activiteiten of infrastructuurfouten?


* Welke notificatiekanalen (e-mail, webhooks, Teams) zijn het meest geschikt?



### 4.4 Sizing, Schaalbaarheid en Retention Policies

* 
**Storage Sizing:** Berekening van de verwachte data-inname (Events Per Second - EPS) en de impact op de schijfruimte.


* 
**Retention Policies:** Welke retentiestrategie (aantal indexen, rotatie op basis van grootte of tijd) past binnen de performantie- en opslaglimieten van de scholengroep?



### 4.5 Integratie met Bestaande Monitoringplatformen (Uitbreiding)

* Analyse van hoe Graylog kan samenwerken of integreren met platformen zoals Grafana, Zabbix of Prometheus.





## 5. Security & Privacy Overwegingen

Beschrijf hoe er rekening wordt gehouden met de beperkingen en wetgeving rondom infrastructuurdata.

* **Data-encryptie:** Beveiliging van logs tijdens transport (TLS/SSL voor Syslog en Beats).
* **Toegangsbeheer (RBAC):** Rollen en rechten binnen Graylog (wie mag welke dashboards en logs inzien).
* **Privacy (GDPR):** Omgang met privacygevoelige gegevens in logs (bijv. IP-adressen of gebruikersnamen van studenten/leerkrachten).



## 6. Conclusie & Aanbevelingen

Een samenvatting van de voorgestelde architectuur en de volgende stappen voor de testfase.