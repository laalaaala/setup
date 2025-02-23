#!/bin/bash
# Stelle sicher, dass der Docker-Dienst läuft, bevor weitere Befehle ausgeführt werden
echo "Starte Docker-Dienste..."
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl start docker.service

# Warte, bis der Docker-Dienst vollständig gestartet ist
echo "Warte auf Docker-Initialisierung..."
until sudo systemctl is-active docker.service > /dev/null 2>&1; do
    sleep 1
done
echo "Docker-Dienst ist aktiv."

# Berechtigungen für die Docker-Socket-Datei setzen
echo "Setze Berechtigungen für Docker-Socket..."
sudo chmod 666 /var/run/docker.sock

# Gruppe hinzufügen und Benutzer anpassen
echo "Konfiguriere Docker-Gruppe und Benutzer..."
sudo groupadd docker || true  # Ignoriere Fehler, falls die Gruppe schon existiert
sudo usermod -aG docker $USER

# Docker-Compose-Plugin installieren
echo "Installiere Docker-Compose-Plugin..."
sudo apt install -y docker-compose-plugin

# Überprüfe die Installation
echo "Überprüfe Docker-Versionen..."
docker --version
docker compose version
