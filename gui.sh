#!/bin/bash
ROOT_PATH="$(dirname "$(readlink -f "$0")")"
cd "$ROOT_PATH"
python3 -m oomox_gui "$@"
