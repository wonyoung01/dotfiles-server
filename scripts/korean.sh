#!/bin/bash

sudo apt update
sudo apt install -y ibus-hangul
sudo apt install -y language-pack-ko fonts-nanum fonts-nanum-coding fonts-nanum-extra

# Reboot is required to apply the changes
