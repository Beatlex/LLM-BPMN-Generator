BPMN-AI Renderer

Ein KI-gestütztes Tool zur automatischen Erstellung, Visualisierung und Validierung von BPMN-Modellen.
Version v0.1 Early Preview

REQUIRES (Bei nutzung der LLM funktion):
- Lokal installiertes Ollama
- laufender Ollama Server(CMD -> ollama serve)
- Mindesten ein installiertes Ollama Modell


🚀 Überblick

Der BPMN-AI Renderer ist ein interaktives Desktop-Tool (Godot Engine 4.5), das natürliche Sprache mithilfe eines lokalen Large Language Models (LLM, z. B. über Ollama) in korrekte, strukturierte BPMN-Prozessmodelle umwandelt.

Ziel ist eine zuverlässige, erklärbare und erweiterbare Architektur zur hybriden Prozessmodellierung:

➤ Der Nutzer beschreibt einen Prozess in Alltagssprache
➤ Das LLM erzeugt daraus ein standardisiertes JSON-BPMN-Modell
➤ Der Renderer visualisiert das Modell automatisch in BPMN-Notation

Das Tool dient sowohl als Prototyp für deine Bachelorarbeit

„Konzeption und prototypische Entwicklung eines LLM-basierten Assistenzsystems zur Generierung von BPMN-Modellen auf Basis dialogischer Prozesslogik“
als auch als ernstzunehmende Grundlage für ein zukünftiges Assistenzsystem.

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
