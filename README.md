BPMN-AI Renderer

Ein KI-gestütztes Tool zur automatischen Erstellung, Visualisierung und Validierung von BPMN-Modellen.
Version v0.1 Early Preview

REQUIRES (Bei nutzung der LLM funktion):
- Lokal installiertes Ollama
- laufender Ollama Server(CMD -> ollama serve)
- Mindesten ein installiertes Ollama Modell


🚀 Überblick

Der BPMN-AI Renderer ist ein interaktives Desktop-Tool (Godot Engine 4.5), das natürliche Sprache mithilfe eines lokalen Large Language Models (LLM, z. B. über Ollama) in korrekte, strukturierte BPMN-Prozessmodelle umwandelt.

<img width="1595" height="896" alt="Homescreen" src="https://github.com/user-attachments/assets/5b3bb5b9-f7b3-47dc-ab2b-2392090d0294" />

Ziel ist eine zuverlässige, erklärbare und erweiterbare Architektur zur hybriden Prozessmodellierung:
➤ Der Nutzer beschreibt einen Prozess in Alltagssprache
➤ Das LLM erzeugt daraus ein standardisiertes JSON-BPMN-Modell
➤ Der Renderer visualisiert das Modell automatisch in BPMN-Notation

Das Tool dient sowohl als Prototyp für eine Bachelorarbeit: „Konzeption und prototypische Entwicklung eines LLM-basierten Assistenzsystems zur Generierung von BPMN-Modellen auf Basis dialogischer Prozesslogik“ als auch als ernstzunehmende Grundlage für ein zukünftiges Assistenzsystem.

Grundfunktionen des BPMN AI Renderer:
**Json Laden um BPMN zu erzeugen**
Lädt Jsons und erstellt aufgrund deren Inhalt ein BPMN.
**Beispiel öffnen**
Öffnet ein vordefiniertes Beispiel 
**Neues Diagramm erstellen**
Ermöglicht, bei korrekter einrichtung der LLM's, ein Dialog basierten Prozess zur generierung eines BPMN's 

Einrichtung des Tools:
Im Hauptmenü unterpunkt Einstellungen auswählen.
Dort wird nun versucht mit Ollama zu kommunizieren und verfügbare Modelle zu Laden.

<img width="1594" height="891" alt="Einstellung" src="https://github.com/user-attachments/assets/cac3cee5-e3cf-4166-b598-da2601d565af" />

Sollte der Ollama Server nicht laufen sollte eine eindeutige Meldung des Prototypen erscheinen.
Bitte sicherstellen das der Ollama Server korrekt läuft (in CMD -> Ollama serve)

Anschließend kann das entsprechende Modell ausgewählt und getestet werden.

<img width="1593" height="898" alt="EinstellungTest" src="https://github.com/user-attachments/assets/8120a39a-940c-4ab3-8892-05dfb82dcdba" />

Im Homescreen 

✨ Features
🧠 KI-gestützte BPMN-Modellgenerierung
Nutzung eines lokal ausgeführten LLMs (z. B. GPT-OSS, Llama 3, etc. über Ollama)
Strukturierter Dialogansatz mit kontrolliertem Master Prompt
Eingeschränkte, robuste BPMN-Domäne:
start_event
end_event
task
exclusive_gateway
parallel_gateway
Validierter Output im JSON-Format
Automatische Erkennung, Parsing und Weitergabe zur Renderer-Engine
