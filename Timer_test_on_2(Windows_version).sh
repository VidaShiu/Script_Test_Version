#!/bin/bash

echo "************************"
echo "Please Enter The Test Time (in seconds) And Press Enter To Confirm."
read -t 5 -p "5 Seconds Buffer Time, Enter Or Wait (Set Default Value): " inputchar
# 使用者有5秒輸入測試時間(sec.)，否則預設為86400秒(24小時)
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
ntpdate time.stdtime.gov.tw  # 初始同步系統時間
sleep 2
sudo timedatectl set-local-rtc 1  # 將 RTC 設為本地時間（同步系統時間）
sleep 2

timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
logfile="RTC_On_Test_$timestamp.txt"

echo "Start The Test..."
echo "=== Test Start ===" > "$logfile"
sudo timedatectl status | grep -E 'Local time|Universal time|RTC time|Time zone' | tee -a "$logfile"

# 擷取初始 offset（系統時間與 NTP 差距）
start_offset=$(ntpdate -q time.stdtime.gov.tw | grep 'offset' | tail -n 1 | awk '{print $10}')
echo "Initial system offset: $start_offset sec" | tee -a "$logfile"

sleep "$a"
echo ""

echo "Test Has Been Completed."
echo "=== Test End ===" >> "$logfile"
sudo timedatectl status | grep -E 'Local time|Universal time|RTC time|Time zone' | tee -a "$logfile"

# 還原 RTC 設定為 UTC
sudo timedatectl set-local-rtc 0
sleep 1

# 擷取結束 offset（系統時間與 NTP 差距）
end_offset=$(ntpdate -q time.stdtime.gov.tw | grep 'offset' | tail -n 1 | awk '{print $10}')
echo "Final system offset: $end_offset sec" | tee -a "$logfile"

# 計算偏移絕對值
abs_offset=$(echo "$end_offset" | awk '{print ($1 < 0) ? -$1 : $1}')

echo ""
echo "Test Result Is:"
if (( $(echo "$abs_offset <= 2" | bc) )); then
  echo "RTC time test: Pass (偏移 $end_offset 秒)" | tee -a "$logfile"
else
  echo "RTC time test: Fail (偏移 $end_offset 秒)" | tee -a "$logfile"
fi

rm -f inputchar.txt
