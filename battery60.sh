#!/bin/bash
MODE_FILE="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
CONF_FILE="/etc/tlp.conf"
echo 1 | sudo tee $MODE_FILE
sudo sed -i 's/^STOP_CHARGE_THRESH_BAT0=.*/STOP_CHARGE_THRESH_BAT0=1/' $CONF_FILE
sudo systemctl restart tlp
