#!/usr/bin/env bash
set -e
./main.lua > out &
sleep 2
timeout 3 nc -u 127.0.0.1 5300 < in || true
diff -u out expected
