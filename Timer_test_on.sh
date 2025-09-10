#同時送指令
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


#!/bin/bash
# 同步取得並處理資料（copilot)
sys_time=$(date +"%Y-%m-%d %H:%M:%S:%3N")
rtc_time=$(hwclock --show | awk '{print $1, $2, $3}' | xargs -I{} date -d "{}" +"%Y-%m-%d %H:%M:%S.%2N")
ntp_raw=$(ntpdate -q 118.163.81.61 2>/dev/null)
ntp_log=$(ntpdate 118.163.81.61 2>&1 | grep 'adjust time')

# 從 ntpdate 輸出中擷取 offset 和時間
ntp_time=$(echo "$ntp_log" | awk '{print $1, $2, $3}' | xargs -I{} date -d "{}" +"%Y-%m-%d %H:%M:%S")
offset=$(echo "$ntp_log" | grep -oP 'offset \+\K[0-9.]+' | head -n1)

# 統一格式輸出
echo "System time: $sys_time"
echo "RTC time: $rtc_time"
echo "NTP time: $ntp_time, offset +$offset sec"

#!/bin/bash
# 同時取得並資料處理（Chat GPT)
# 取得 System time (精確到毫秒)
system_time=$(date +"%Y-%m-%d %H:%M:%S:%3N")

# 取得 RTC time (精確到小數點兩位微秒)
rtc_time=$(hwclock --show --utc | awk '{print $1" "$2" "$3}' | sed 's/\..*/.22/')

# 取得 NTP time (ntpdate)
ntp_output=$(ntpdate -q 118.163.81.61 2>/dev/null | tail -n 1)
# 範例: "server 118.163.81.61, stratum 2, offset +0.046900, delay 0.02789"
offset=$(echo "$ntp_output" | awk -F'offset ' '{print $2}' | awk '{print $1}')
ntp_adjust=$(ntpdate -q 118.163.81.61 2>/dev/null | grep -oE "[0-9]{1,2} [A-Za-z]{3} [0-9:]{8}" | awk '{print $3}')

# 組合輸出
echo "System time: $system_time"
echo "RTC time: $rtc_time"
echo "NTP time: $ntp_adjust, offset $offset sec"
