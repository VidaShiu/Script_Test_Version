#!/bin/bash

echo "************************"
echo "Please Enter The Test Time (in seconds) And Press Enter To Confirm."
read -t 5 -p "5 Seconds Buffer Time, Enter Or Wait (Set Default Value): " inputchar
echo $inputchar > inputchar.txt
a=$(cat inputchar.txt)
dest=
if [ "$a" = "$dest" ]; then
  echo "Set The Test Time Duration: 24 hrs"
  echo
  a=86400
else 
  echo "Saved And Execute That Settings"
  sleep 1
fi 

echo "Time Is Initializing..."
echo ""
sudo ntpdate -b time.stdtime.gov.tw
sleep 2
sudo timedatectl set-local-rtc 1
sleep 2

timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
logfile="RTC_On_Test_$timestamp.txt"

echo "Start The Test..."
echo ""
date '+%Y-%m-%d %H:%M:%S:%3N' | tee -a "$logfile"
sudo hwclock --show | tee -a "$logfile"
sudo ntpdate -q time.stdtime.gov.tw | tee -a "$logfile"

sleep $a
echo ""

echo "Test Has Been Completed."
echo ""
date '+%Y-%m-%d %H:%M:%S:%3N' | tee -a "$logfile"
sudo hwclock --show | tee -a "$logfile"
sudo ntpdate -q time.stdtime.gov.tw | tee -a "$logfile"

sleep 1
sudo timedatectl set-local-rtc 0

echo ""
echo "Analyzing Time Drift..."
echo ""

# 擷取最後一次時間紀錄
rtc=$(grep -A1 "Test Has Been Completed." "$logfile" | grep -E '^[0-9]{4}-' | head -n1 | sed 's/:/./')
sys=$(grep -A1 "Test Has Been Completed." "$logfile" | grep -E '^[0-9]{4}-' | tail -n1)
ntp_offset=$(grep -A5 "Test Has Been Completed." "$logfile" | grep offset | head -n1 | grep -oP 'offset\s+\+?\K[0-9.]+' )

# 轉換時間為毫秒
rtc_ms=$(date -d "$rtc" +%s%3N)
sys_ms=$(date -d "$sys" +%s%3N)
ntp_ms=$(echo "$sys_ms - ($ntp_offset * 1000)" | bc | awk '{printf "%.0f", $0}')

# 計算差距（秒，浮點）
rtc_ntp_diff=$(echo "scale=4; ($rtc_ms - $ntp_ms)/1000" | bc | sed 's/^-//')
sys_ntp_diff=$(echo "scale=4; ($sys_ms - $ntp_ms)/1000" | bc | sed 's/^-//')

# 判斷 Pass/Fail
rtc_status=$(echo "$rtc_ntp_diff > 2" | bc -l)
sys_status=$(echo "$sys_ntp_diff > 2" | bc -l)

echo "RTC vs NTP: ${rtc_ntp_diff} s → $( [ "$rtc_status" -eq 1 ] && echo "Fail" || echo "Pass" )"
echo "SYS vs NTP: ${sys_ntp_diff} s → $( [ "$sys_status" -eq 1 ] && echo "Fail" || echo "Pass" )"
