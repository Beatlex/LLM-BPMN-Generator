<#
    installer.ps1 – Interaktiver Installer für das BPMN-Assistenzsystem
    Funktionen:
    - Prüft Voraussetzungen
    - Installiert Ollama (optional)
    - Lässt den Nutzer ein Modell auswählen
    - Lädt das LLM-Modell über Ollama
    - Optional: Python-Umgebung einrichten
#>

Write-Host "==========================================="
Write-Host "   BPMN Assistenzsystem  Installer"
Write-Host "==========================================="
Write-Host ""
Write-Host "Dieses Setup führt Sie durch die Installation."
Write-Host ""

# -------------------------------------------
# Prüfen ob das Skript als Administrator läuft
# -------------------------------------------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $IsAdmin) {
    Write-Host "Bitte starten Sie dieses Skript als Administrator!"
    Write-Host "   Rechtsklick → 'Mit PowerShell ausführen als Administrator'"
    exit
}

# -------------------------------------------
# Prüfen ob Ollama installiert ist
# -------------------------------------------
Write-Host ""
Write-Host " Prüfe ob Ollama installiert ist..."

$ollamaExists = Get-Command "ollama" -ErrorAction SilentlyContinue

if (-not $ollamaExists) {
    Write-Host "Ollama wurde nicht gefunden."
    Write-Host "Möchten Sie Ollama jetzt installieren? (J/N)"
    $installOllama = Read-Host

    if ($installOllama -eq "J" -or $installOllama -eq "j") {
        Write-Host "⬇Lade Ollama Installer herunter..."
        Invoke-WebRequest "https://ollama.com/download/OllamaSetup.exe" -OutFile "OllamaSetup.exe"
        Write-Host "Starte Installer..."
        Start-Process ".\OllamaSetup.exe" -Wait
        Write-Host "Ollama wurde installiert."
    }
    else {
        Write-Host "Ollama wird benötigt. Installer wird beendet."
        exit
    }
}
else {
    Write-Host "Ollama ist installiert."
}

# -------------------------------------------
# Modellauswahl
# -------------------------------------------
Write-Host ""
Write-Host "==========================================="
Write-Host "     LLM-Modellauswahl"
Write-Host "==========================================="
Write-Host ""
Write-Host "Bitte wählen Sie ein Modell:"
Write-Host "1) LLaMA 3.1 8B   (geringer VRAM, für Laptops)"
Write-Host "2) LLaMA 3.1 12B  (ausgewogen, Empfehlung)"
Write-Host "3) Mixtral 8x7B   (schnell & stark, benötigt GPU)"
Write-Host "4) LLaMA 3.1 70B  (sehr hohe Qualität)"
Write-Host "5) LLaMA 3.1 80B  (maximale Qualität)"
Write-Host "6) Kein Modell installieren (ich mache das später)"
Write-Host ""

$choice = Read-Host "Ihre Auswahl (1-6)"

switch ($choice) {
    "1" { $model = "llama3.1:8b" }
    "2" { $model = "llama3.1:12b" }
    "3" { $model = "mixtral:8x7b" }
    "4" { $model = "llama3.1:70b" }
    "5" { $model = "llama3.1:80b" }
    "6" {
        Write-Host "Installation übersprungen."
        $model = $null
    }
    default {
        Write-Host "Ungültige Eingabe. Bitte Installer erneut starten."
        exit
    }
}

# -------------------------------------------
# Modell herunterladen
# -------------------------------------------
if ($model) {
    Write-Host ""
    Write-Host "Lade Modell herunter: $model"
    ollama pull $model
    Write-Host "Modell erfolgreich installiert."
}

# -------------------------------------------
# Optional: Python-Umgebung einrichten
# -------------------------------------------
Write-Host ""
Write-Host "Möchten Sie eine Python-Umgebung für das Assistenzsystem einrichten? (J/N)"
$setupPython = Read-Host

if ($setupPython -eq "J" -or $setupPython -eq "j") {
    Write-Host "Erstelle virtuelle Umgebung..."
    python -m venv venv
    Write-Host "Virtuelle Umgebung erstellt."

    Write-Host "Installiere Python-Abhängigkeiten..."
    .\venv\Scripts\pip install -r requirements.txt
    Write-Host "Python-Konfiguration abgeschlossen."
}
else {
    Write-Host "Python-Setup übersprungen."
}

# -------------------------------------------
# Fertig
# -------------------------------------------
Write-Host ""
Write-Host "==========================================="
Write-Host " ✅ Installation abgeschlossen! "
Write-Host "==========================================="
Write-Host ""
Write-Host "Sie können das System jetzt über 'start.ps1' starten."
Write-Host ""
