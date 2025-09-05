#!/bin/bash

echo "************************"
echo "Please Enter The Test Time (in seconds) And Press Enter To Confirm."
read -t 5 -p "5 Seconds Buffer Time, Enter Or Wait (Set Default Value): " inputchar
echo $inputchar > inputchar.txt
a=$(cat inputchar.txt)
rm -f inputchar.txt

if [ -z "$a" ]; then
  echo "Set The Test Time Duration: 24 hrs"
  a=86400
else 
  echo "Saved And Execute That Settings: $a seconds"
  sleep 1
fi 

echo "Time Is Initializing..."
ntpdate time.stdtime.gov.tw
sleep 2
sudo timedatectl set-local-rtc 1
sleep 2

timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
logfile="RTC_On_Test_$timestamp.txt"

echo "=== Test Start ===" | tee "$logfile"
sudo timedatectl status | grep -E 'Local time|Universal time|RTC time|Time zone' | tee -a "$logfile"

# 擷取初始 offset
start_offset=$(ntpdate -q time.stdtime.gov.tw | grep -oP 'offset\s+\K[-+]?[0-9.]+')
echo "Initial system offset: $start_offset sec" | tee -a "$logfile"

sleep "$a"
echo ""

echo "Test Has Been Completed." | tee -a "$logfile"
echo "=== Test End ===" | tee -a "$logfile"
sudo timedatectl status | grep -E 'Local time|Universal time|RTC time|Time zone' | tee -a "$logfile"

sudo timedatectl set-local-rtc 0
sleep 1

# 擷取結束 offset
end_offset=$(ntpdate -q time.stdtime.gov.tw | grep -oP 'offset\s+\K[-+]?[0-9.]+')
echo "Final system offset: $end_offset sec" | tee -a "$logfile"

# 計算偏移絕對值
abs_offset=$(echo "$end_offset" | awk '{print ($1 < 0) ? -$1 : $1}')

echo "" | tee -a "$logfile"
echo "Test Result Is:" | tee -a "$logfile"
if (( $(echo "$abs_offset <= 2" | bc) )); then
  echo "RTC time test: Pass (偏移 $end_offset 秒)" | tee -a "$logfile"
else
  echo "RTC time test: Fail (偏移 $end_offset 秒)" | tee -a "$logfile"
fi
