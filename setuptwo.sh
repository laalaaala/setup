#!/bin/bash

# Setze das richtige Home-Verzeichnis
USER_HOME="/home/q-tech.dev"

# 1. System-Updates
sudo apt update && sudo apt upgrade -y

# 2. Notwendige Pakete installieren
sudo apt install xserver-xorg xinit openbox chromium-browser unclutter --no-install-recommends x11-xserver-utils xdotool xterm hostapd dnsmasq fbi -y

# 3. Erstelle notwendige Chromium-Verzeichnisse
mkdir -p "$USER_HOME/.config/chromium"
mkdir -p "$USER_HOME/.cache/chromium"
mkdir -p "$USER_HOME/.local/share/chromium"
mkdir -p "$USER_HOME/.config/chromium-profile"
sudo chown -R q-tech.dev:q-tech.dev "$USER_HOME/.config/chromium" "$USER_HOME/.cache/chromium" "$USER_HOME/.local/share/chromium" "$USER_HOME/.config/chromium-profile"

# 4. Stelle sicher, dass das Xorg-Verzeichnis existiert und die richtigen Berechtigungen hat
mkdir -p /home/q-tech.dev/.local/share/xorg
sudo chown -R q-tech.dev:q-tech.dev /home/q-tech.dev/.local/share/xorg
sudo chmod -R 755 /home/q-tech.dev/.local/share/xorg

# 5. Autostart-Konfiguration für Openbox
mkdir -p "$USER_HOME/.config/openbox"
cat <<EOF | tee "$USER_HOME/.config/openbox/autostart"
export DISPLAY=:0
$USER_HOME/start_chromium.sh &
unclutter -idle 0 &
EOF
sync

# 6. Chromium-Startskript erstellen
cat <<EOF | tee "$USER_HOME/start_chromium.sh"
#!/bin/bash
export DISPLAY=:0
chromium-browser --user-data-dir="$USER_HOME/.config/chromium-profile" --noerrdialogs --disable-infobars --kiosk http://localhost:3000 --disable-features=RendererCodeIntegrity --disable-background-timer-throttling --disable-renderer-backgrounding || sudo reboot
EOF
chmod +x "$USER_HOME/start_chromium.sh"
sync

# 7. Openbox beim Start laden
cat <<EOF | tee "$USER_HOME/.xinitrc"
exec openbox-session
EOF
sync

# 8. Automatischen GUI-Start sicherstellen
cat <<EOF > "$USER_HOME/.bash_profile"
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF
sync

# 9. Hotspot-Konfiguration
sudo mkdir -p /etc/hostapd
cat <<EOF | sudo tee /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=Menu-Software.de
hw_mode=g
channel=7
wpa=2
wpa_passphrase=MenuSoftware2025
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF
sync

# 10. Statische IP-Adresse für wlan0 setzen
cat <<EOF | sudo tee /etc/dhcpcd.conf
interface wlan0
static ip_address=1.1.1.1/24
nohook wpa_supplicant
EOF
sync

# 11. DHCP-Server konfigurieren
cat <<EOF | sudo tee /etc/dnsmasq.conf
interface=wlan0
dhcp-range=1.1.1.2,1.1.1.20,255.255.255.0,24h
EOF
sync

# 12. Hotspot-Dienste aktivieren
sudo systemctl unmask hostapd
sudo systemctl enable hostapd dnsmasq
sudo systemctl restart hostapd dnsmasq

# 13. Standby und Bildschirmschoner deaktivieren
sudo mkdir -p /etc/X11/xorg.conf.d
cat <<EOF | sudo tee /etc/X11/xorg.conf.d/10-monitor.conf
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection

Section "Monitor"
    Identifier "Monitor0"
    Option "DPMS" "false"
EndSection
EOF
sync

# 14. WLAN-Sperre beim Boot entfernen
cat <<EOF | sudo tee /etc/rc.local
#!/bin/sh -e
rfkill unblock wlan
sudo ifconfig wlan0 1.1.1.1 netmask 255.255.255.0 up
exit 0
EOF
sudo chmod +x /etc/rc.local
sync

# 15. Hostapd-Dienstverzögerung für stabilen Start
sudo mkdir -p /etc/systemd/system
cat <<EOF | sudo tee /etc/systemd/system/hostapd-restart.service
[Unit]
Description=Restart hostapd after network initialization
After=network.target

[Service]
ExecStart=/bin/bash -c "sleep 10 && systemctl restart hostapd"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable hostapd-restart.service
sync

# **15.1. PNG-Splash-Screen einrichten**
echo "Richte Splash-Screen ein..."

# 15.1.4 Service für den Splash-Screen anlegen
cat <<EOF | sudo tee /etc/systemd/system/splashscreen.service
[Unit]
Description=Custom Boot Splash Screen
DefaultDependencies=no
After=local-fs.target
Before=plymouth-quit.service

[Service]
ExecStart=/usr/bin/fbi -T 1 -noverbose -a /home/q-tech.dev/setup/qtoneos.png
StandardInput=tty
StandardOutput=tty
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
EOF
sudo systemctl enable splashscreen.service

# 15.1.5 Skript zum Beenden des Splash-Screens, wenn Chromium startet
cat <<EOF | sudo tee /usr/local/bin/stop_splash.sh
#!/bin/bash
sleep 5  # Warte 5 Sekunden, damit Chromium sicher gestartet ist
sudo systemctl stop splashscreen.service
EOF
sudo chmod +x /usr/local/bin/stop_splash.sh

# 15.1.6 Autostart für Splash-Screen-Stopp
echo "/usr/local/bin/stop_splash.sh &" | sudo tee -a "$USER_HOME/.bash_profile"

sync

# 16. Docker installieren
echo "Installiere Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Entferne das temporäre Installationsskript
rm -f get-docker.sh

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

# 16. Abschluss
echo "Docker-Setup abgeschlossen. Bitte Raspberry Pi neu starten."

# 16. Abschluss
echo "Setup abgeschlossen. Bitte Raspberry Pi neu starten."
