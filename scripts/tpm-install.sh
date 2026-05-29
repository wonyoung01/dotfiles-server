#!/bin/bash
if [ -d ~/.tmux/plugins/tpm/.git ]; then git -C ~/.tmux/plugins/tpm pull --ff-only; else git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm; fi
