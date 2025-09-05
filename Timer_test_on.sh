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
  echo "Saved And Excute That Settings"
  sleep 1
fi 
echo "Time Is Initializing..."
ntpdate time.stdtime.gov.tw #與NTP(tock.stdtime.gov.tw)同步系統時間
sleep 2
sudo timedatectl set-local-rtc 1 #將硬體RTC同步為系統時間
sleep 2
timestamp=$(date +"%Y-%m-%d-%H-%M-%S") #建立時間戳記(格式：YYYY-MM-DD-HH-MM-SS)
logfile="RTC_On_Test_$timestamp.txt" #使用時間戳記命名log

echo "Start The Test..."
sudo ntpdate -q time.stdtime.gov.tw
# 顯示當前所有時間，作為測試起點
output=$(sudo ntpdate -q time.stdtime.gov.tw)
echo "$output" >> "$logfile"
# 擷取時間資訊

sleep $a
echo ""

echo "Test Has Been Completed."
sudo sudo ntpdate -q time.stdtime.gov.tw
# 顯示當前所有時間，作為測試終點
output=$(sudo ntpdate -q time.stdtime.gov.tw)
echo "$output" >> "$logfile"
# 擷取時間資訊
sleep 1
sudo timedatectl set-local-rtc 0
# 還原RTC設定為UTC

echo "Test Result Is:"
local_time=$(echo "$output" | grep 'Local time' | awk -F': ' '{print $2}')
rtc_time=$(echo "$output" | grep 'RTC time' | awk -F':   ' '{print $2}')
# 擷取時間字串

local_ts=$(date -d "$local_time" +%s)
rtc_ts=$(date -d "$rtc_time" +%s)
# 轉換為 timestamp

offset=$((local_ts - rtc_ts))
abs_offset=$(echo "$offset" | awk '{print ($1 < 0) ? -$1 : $1}')
# 計算偏移

if [ "$abs_offset" -le 2 ]; then
  echo "RTC time test: Pass (偏移 $offset 秒)"
else
  echo "RTC time test: Fail (偏移 $offset 秒)"
fi
# 判斷是否通過±2秒標準
rm -f inputchar.txt
