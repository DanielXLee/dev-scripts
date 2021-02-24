#!/bin/bash

# Get all process mem usage from smaps
cat /proc/*/smaps | awk '/Pss/ {sum += $2} END {print sum}'


cat /proc/*/smaps | awk '/Swap/ {sum += $2} END {print sum}'
# Get all process mem usage from status
cat /proc/*/status | grep VmRSS | awk '/VmRSS/ {sum += $2} END {print sum}'
