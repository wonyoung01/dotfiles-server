#!/bin/bash

sudo apt update
# Install pandoc and zathura for PDF viewing and conversion
sudo apt install -y pandoc zathura poppler-utils
# Install LaTeX for PDF generation
# Note: This will install a large number of packages, so you may want to customize this based on your needs
sudo apt install -y texlive-full

# Install tdf
sudo apt update
sudo apt install -y pkg-config libfontconfig1-dev
cargo install --git https://github.com/itsjunetime/tdf.git tdf-viewer
