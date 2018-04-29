#!/usr/bin/env bash
./main.lua > out &
sleep 2
nc -w 3 -u 127.0.0.1 5300 < in
diff -u out expected