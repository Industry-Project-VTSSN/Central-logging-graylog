# Eindrapport: Centrale Logging en Monitoring met Graylog

## 1. Projectcontext

Dit eindrapport beschrijft het ontwerp, de implementatie en de validatie van een centrale logging- en monitoringomgeving voor vzw Vrije Technische Scholen Sint-Niklaas (VTSSN).

**Projectperiode:** 18/05/2026 - 19/06/2026

De organisatie beheert een heterogene infrastructuur over meerdere campussen en locaties, met als belangrijkste uitdaging dat logs verspreid en gefragmenteerd beschikbaar waren. Daardoor waren detectie, troubleshooting en security-analyse traag en onvoldoende uniform.

## 2. Doelstellingen

De centrale doelstelling van dit project is het realiseren van een robuust, schaalbaar en beheerbaar loggingplatform dat:

1. logs centraliseert over kritieke infrastructuurcomponenten;
2. snelle troubleshooting mogelijk maakt;
3. basis security monitoring ondersteunt;
4. dashboards en alerts operationeel inzetbaar maakt;
5. compliant blijft met privacy- en bewaarbeleid.

## 3. Scope van de oplossing

### 3.1 In scope

1. Windows en Hyper-V eventverwerking via WEF en Winlogbeat.
2. Syslog-ingestie van firewalls en netwerkapparatuur.
3. Centrale verwerking in Graylog met pipeline parsing en stream routing.
4. Opslag in OpenSearch (via Graylog Data Node stack).
5. Dashboard- en alertconfiguratie.
6. Technische documentatie en testaanpak.

### 3.2 Out of scope

1. Diepgaande performantiebenchmarking op lange termijn.
2. Volledige disaster recovery oefening inclusief restore-scenario's.

## 4. Doelarchitectuur

De gekozen oplossing is een Docker-gebaseerde Graylog stack met drie kerncomponenten:

1. Graylog server voor ingestie, verwerking, routing en visualisatie.
2. Data node/OpenSearch voor indexering en zoekfunctionaliteit.
3. MongoDB voor configuratie- en metadataset.

### 4.1 Logbronnen en datastromen

#### Windows/Hyper-V flow

1. Hyper-V/Windows hosts genereren events.
2. Events worden via Windows Event Forwarding naar een collector gestuurd.
3. Winlogbeat op de collector leest de events en verzendt ze naar Graylog via TCP 5044.

#### Netwerk/Security flow

1. Firewalls en netwerkapparatuur verzenden syslog naar hostpoort UDP 514.
2. In Docker wordt dit verkeer doorgestuurd naar de Graylog syslog input.
3. Graylog verwerkt en normaliseert de berichten in pipelines.

## 5. Technische implementatie

De implementatie is opgebouwd uit de volgende operationele onderdelen:

1. Installatie van de Graylog stack via Docker Compose.
2. Configuratie van inputs voor Beats en Syslog.
3. Inrichting van streams en index sets.
4. Pipeline parsing voor normalisatie van vendor-specifieke logs.
5. Opbouw van dashboards per operationele use case.
6. Configuratie van alerts en notificatiekanalen.

Belangrijk ontwerpprincipe: uniforme velden en consistente routing, zodat dashboards over verschillende bronnen heen bruikbaar blijven.

## 6. Security, privacy en governance

Het ontwerp houdt rekening met GDPR en operationele governance:

1. Dataminimalisatie: alleen noodzakelijke loggegevens worden gecentraliseerd.
2. Beperkte bewaartermijnen: hot storage en archiefretentie volgens beleid.
3. RBAC: rechten op basis van rol en taak.
4. TLS-gebaseerde beveiliging van transport waar nodig.
5. Auditability via logging van beheeracties en raadpleging.

## 7. Testaanpak

De validatie van de oplossing is uitgewerkt in een afzonderlijk testplan met prioritaire testcases.

### 7.1 Testfocus

1. End-to-end ingestiepad voor WEF/Winlogbeat en Syslog.
2. Correcte parsing en field normalisatie.
3. Correcte streamtoewijzing en indexering.
4. Zichtbaarheid in dashboards.
5. Triggergedrag van alerts.

### 7.2 Testdocumenten

1. [testplan_logging_flow.md](./testplan_logging_flow.md)
2. [testresults.md](./testresults.md)

## 8. Resultaat en evaluatie

Op basis van de technische uitwerking is een centrale loggingarchitectuur gerealiseerd die:

1. versnipperde logging centraliseert;
2. operationeel beheer versnelt;
3. de detectiecapaciteit voor incidenten verhoogt;
4. beter schaalbaar en reproduceerbaar is dan een klassieke VM-only aanpak.

De oplossing is bovendien onderhoudsvriendelijk dankzij containerisatie en duidelijke operationele documentatie.

## 9. Risico's en aandachtspunten

Voor productiegebruik blijven onderstaande aandachtspunten belangrijk:

1. Correcte en blijvende port-mapping van syslog ingestie op host en container.
2. Regelmatige validatie van pipeline parsing na firmware- of vendorwijzigingen.
3. Continue tuning van dashboards en alerts om ruis te beperken.
4. Behoud van duidelijke operationele verantwoordelijkheden voor beheer, monitoring en opvolging.

## 10. Aanbevolen vervolgacties

1. Formele periodieke review van streams, retention en alertregels.
2. Invoering van een change-procedure voor parsing- en dashboardwijzigingen.
3. Opbouw van maandelijkse kwaliteitsrapportage met ingestie- en alertstatistieken.
4. Uitbreiding met extra use cases (bijvoorbeeld geavanceerde security correlatie).

## 11. Bronnen en referenties

- [technical_analysis.md](./technical_analysis.md)
- [installation_guide.md](./installation_guide.md)
- [configuration_guide.md](./configuration_guide.md)
- [syslog_configuration_guide.md](./syslog_configuration_guide.md)
- [logging_flow_guide.md](./logging_flow_guide.md)
- [dashboard_configuration_guide.md](./dashboard_configuration_guide.md)
- [alert_configuration.md](./alert_configuration.md)
- [troubleshooting_guide.md](./troubleshooting_guide.md)
- [testplan_logging_flow.md](./testplan_logging_flow.md)
- [testresults.md](./testresults.md)

## 12. Aan te vullen projectgegevens

Onderstaande gegevens kunnen nog worden toegevoegd om dit eindrapport volledig oplever-klaar te maken:

1. Omgevingsgegevens (test, acceptatie, productie).
2. Concreet testresultaat per testcase (Pass/Fail/Blocked).
3. Eventuele openstaande defects en geplande mitigaties.

### 12.1 Omgevingsgegevens

Vul per omgeving minimaal het volgende in:

1. Doel van de omgeving (Test, Acceptatie, Productie).
2. Hostnaam/IP en locatie.
3. Belangrijkste actieve poorten (bijvoorbeeld 9000, 5044, 514).
4. Versies van Graylog, Data Node/OpenSearch en MongoDB.
5. Datum van laatste succesvolle health check.

Voorbeeld formaat:

- Test: [host/IP], Graylog [versie], laatste check [datum].
- Acceptatie: [host/IP], Graylog [versie], laatste check [datum].
- Productie: [host/IP], Graylog [versie], laatste check [datum].

### 12.2 Concreet testresultaat per testcase

Vul per testcase (TC-01 t.e.m. TC-10) het volgende in:

1. Status: Pass / Fail / Blocked.
2. Uitvoerdatum en uitvoerder.
3. Korte bewijsreferentie (screenshot, queryresultaat of logextract).
4. Opmerking of defectreferentie bij Fail/Blocked.

Samenvatting die je onder dit hoofdstuk kan opnemen:

1. Totaal aantal testcases.
2. Aantal Pass, Fail en Blocked.
3. Eindoordeel: Go of No-Go (met voorwaarden indien van toepassing).

### 12.3 Openstaande defects en mitigaties

Voor elk openstaand punt beschrijf:

1. Defect-ID en korte titel.
2. Impact (laag, medium, hoog) op beschikbaarheid, integriteit of operationeel beheer.
3. Tijdelijke workaround.
4. Definitieve mitigatie of fix-plan.
5. Eigenaar en doelopleverdatum.

Voorbeeld formaat:

- DEF-01 - [titel], impact [medium], workaround [omschrijving], fix [omschrijving], eigenaar [naam], target [datum].

## 13. Opleverbeslissing (Go/No-Go)

**Beslissing:** 

**Goedkeurders:**

1. ICT-coördinator Pascal Savels
2. Adjunct ICT-coördinator Jonas Cap
