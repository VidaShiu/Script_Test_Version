#!/bin/bash

echo "===== Unified Time Snapshot ====="

(
  echo "[System Time]"
  date +"%Y-%m-%d-%H-%M-%S"
) &

(
  echo "[RTC Time]"
  hwclock --show
) &

(
  echo "[NTP Query]"
  ntpdate -q time.stdtime.gov.tw
) &

wait
echo "===== End Snapshot ====="
