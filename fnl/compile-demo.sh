#!/bin/bash
set -e
./fennel --require-as-include --compile cfillion_reaimgui-demo.fnl > compiled-demo.lua
