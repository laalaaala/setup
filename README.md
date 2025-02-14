# setup.sh
sudo apt install git -y

git clone https://github.com/laalaaala/setup.git
#
chmod +x setup.sh

sudo ./setup.sh
#

#wenn bildschirm problem 

sudo nano ~/.bash_profile"

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi

#
#wenn bildshcirm problem weiterhin besteht

mkdir -p /home/q-tech.dev/.local/share/xorg

sudo chown -R q-tech.dev:q-tech.dev /home/q-tech.dev/.local/share/xorg

sudo chmod -R 755 /home/q-tech.dev/.local/share/xorg

#
#Hotspot porblem beheben

sudo ifconfig wlan0 1.1.1.1 netmask 255.255.255.0 up
#

#Splashscreen einrcihten

sudo nano /boot/config.txt

disable_splash=1

avoid_warnings=1

sudo nano /boot/cmdline.txt

console=tty3 quiet splash plymouth.ignore-serial-consoles loglevel=0 vt.global_cursor_default=0

sudo systemctl enable splashscreen.service


#
#Überprüfung

ls -l /home/pi/.config/openbox/autostart

ls -l /home/pi/start_chromium.sh

ls -l /etc/hostapd/hostapd.conf

ls -l /etc/dhcpcd.conf

ls -l /etc/dnsmasq.conf

ls -l /etc/X11/xorg.conf.d/10-monitor.conf

ls -l /etc/rc.local

ls -l /etc/systemd/system/hostapd-restart.service

