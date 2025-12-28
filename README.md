# BPMN-AI Renderer

**Version:** v0.1 – Early Preview

Ein KI-gestütztes Desktop-Tool zur automatischen Erstellung, Visualisierung und Validierung von BPMN-Modellen auf Basis natürlicher Sprache.

<img width="1595" height="896" alt="Homescreen" src="https://github.com/user-attachments/assets/5b3bb5b9-f7b3-47dc-ab2b-2392090d0294" />
---

## Überblick

Der **BPMN-AI Renderer** ist ein interaktives Desktop-Tool (Godot Engine 4.5), das natürliche Sprache mithilfe eines lokal ausgeführten Large Language Models (LLM, z. B. über Ollama) in korrekte und strukturierte BPMN-Prozessmodelle überführt.

Ziel ist eine **zuverlässige, erklärbare und erweiterbare Architektur** zur hybriden Prozessmodellierung:

* Der Nutzer beschreibt einen Prozess in Alltagssprache
* Das LLM erzeugt daraus ein standardisiertes JSON-BPMN-Modell
* Der Renderer visualisiert das Modell automatisch in BPMN-Notation

Das Tool dient sowohl als **Prototyp im Rahmen einer Bachelorarbeit**

> *„Konzeption und prototypische Entwicklung eines LLM-basierten Assistenzsystems zur Generierung von BPMN-Modellen auf Basis dialogischer Prozesslogik“*

als auch als Grundlage für ein zukünftig produktionsnahes Assistenzsystem.

---

## Voraussetzungen (für LLM-Funktionalität)

Für die Nutzung der KI-Funktionen sind folgende Komponenten erforderlich:

* Lokal installierte **Ollama**-Distribution
* Laufender Ollama-Server

  ```bash
  ollama serve
  ```
* Mindestens ein installiertes Ollama-Modell (z. B. Llama 3)

---

## Grundfunktionen

### JSON laden

Lädt ein vorhandenes JSON-BPMN-Modell und erzeugt daraus automatisch ein BPMN-Diagramm.

### Beispiel öffnen

Öffnet ein vordefiniertes Beispielmodell zur Demonstration der Funktionalität.

### Neues Diagramm erstellen

Ermöglicht – bei korrekt eingerichteter LLM-Umgebung – einen **dialogbasierten Prozess**, aus dem automatisch ein BPMN-Modell generiert wird.

---

## Einrichtung des Tools
<img width="1589" height="894" alt="EinstellungModell" src="https://github.com/user-attachments/assets/8fd8544e-65ba-49ac-8b9a-380231724fa9" />

1. Im Hauptmenü den Menüpunkt **Einstellungen** auswählen.
2. Das Tool versucht automatisch, eine Verbindung zum lokalen Ollama-Server herzustellen und verfügbare Modelle zu laden.
3. Falls der Ollama-Server nicht erreichbar ist, erscheint eine eindeutige Fehlermeldung.

Bitte sicherstellen, dass der Ollama-Server korrekt läuft:

```bash
ollama serve
```

4. Anschließend kann ein verfügbares Modell ausgewählt und getestet werden.
<img width="1593" height="898" alt="EinstellungTest" src="https://github.com/user-attachments/assets/8120a39a-940c-4ab3-8892-05dfb82dcdba" />
---

## Features

### KI-gestützte BPMN-Modellgenerierung

* Nutzung eines lokal ausgeführten LLMs (z. B. GPT-OSS, Llama 3 über Ollama)
* Strukturierter, kontrollierter Dialogansatz mit festem Master-Prompt
* Eingeschränkte und robuste BPMN-Domäne:

  * `start_event`
  * `end_event`
  * `task`
  * `exclusive_gateway`
  * `parallel_gateway`
* Validierter Output im JSON-Format
* Automatische Erkennung, Parsing und Übergabe an die Renderer-Engine

---

## Status

Dieses Projekt befindet sich aktuell im **Early-Preview-Stadium**. Schnittstellen, Datenformate und Funktionsumfang können sich noch aktiv ändern.

---

Beispiele

Die folgenden Beispiele zeigen exemplarisch, wie der BPMN-AI Renderer natürliche Sprache in strukturierte BPMN-Modelle überführt.

Beispiel 1: Einfacher linearer Prozess
Natürliche Sprache (Eingabe)

Der Prozess beginnt mit einer Bestellung.
Danach wird die Bestellung geprüft.
Anschließend wird sie versendet und der Prozess endet.

Erzeugtes BPMN-JSON
[
  {
    "element_id": "0",
    "element_name": "Bestellung eingehen",
    "element_type": "start_event",
    "flows_to": ["1"],
    "outputs": { "right": "", "down": "" },
    "lane_id": "",
    "pool_id": ""
  },
  {
    "element_id": "1",
    "element_name": "Bestellung prüfen",
    "element_type": "task",
    "flows_to": ["2"],
    "outputs": { "right": "", "down": "" },
    "lane_id": "",
    "pool_id": ""
  },
  {
    "element_id": "2",
    "element_name": "Bestellung versenden",
    "element_type": "task",
    "flows_to": ["3"],
    "outputs": { "right": "", "down": "" },
    "lane_id": "",
    "pool_id": ""
  },
  {
    "element_id": "3",
    "element_name": "Prozess beendet",
    "element_type": "end_event",
    "flows_to": [],
    "outputs": { "right": "", "down": "" },
    "lane_id": "",
    "pool_id": ""
  }
]

Gerendertes BPMN-Diagramm

<img width="1600" height="900" alt="Gerendertes BPMN – Einfacher linearer Prozess" src="https://github.com/user-attachments/assets/19a3b437-5f2d-4e50-a0bd-3d2e200ecf85" />
