#!/bin/bash
:<< EOF
每1分钟收集次服务器信息
*/1 * * * * main.sh
cpu 内存 网卡
EOF

set -e

# 当前目录
dir=$(dirname $0)
# 引入配置
source $dir/config.sh
# 当前时间
now=$(date +'%F %T')
# 没有就新建
if [[ ! -d $TEMP_DIR ]]; then
  mkdir -p $TEMP_DIR
fi

# 获取最近一条log
parse_last_log() {
  # 没有找到文件就返回0
  if [[ ! -s ${TEMP_DIR}/$1 ]]; then
    echo "0 0"
    exit
  fi
  # 临时变量key
  local key
  # 为1表示行，为2表示块
  local type=1
  # 声明关联数组
  declare -A row
  while read line
  do
    if [[ $line == '======' ]]; then
      type=1
      continue
    fi
    if [[ $line =~ ^">>" ]]; then
      type=2
      key=${line##*>}
      continue
    fi
    if [[ $type == 1 ]]; then
      array=($line)
      # 截取数组剩余元素为value
      v_arr=${array[@]:1:$[ ${#array[@]} - 1 ]}
      row[${array[0]}]=${v_arr[@]}
    elif [[ $type == 2 ]]; then
      row[$key]="${row[$key]}\n$line"
    fi
  done < ${TEMP_DIR}/$1
  echo "${row['接收流量']} ${row['发送流量']}"
}

# 发送钉钉通知
send_notification() {
  # 发送钉钉通知
  curl "https://oapi.dingtalk.com/robot/send?access_token=$DINGTALK_ACCESS_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"msgtype\": \"text\",\"text\": {\"content\": \"$1\"}}" \
  > /dev/null 2>&1
}

# 网络信息收集
network_info() {
  # 外网ip连接
  connections=$(ss -antup | egrep -i '[^0-9](([2-9][0-9]*)|(1[1-6,8]*)|(10[0-9])|(17[0,1,3-9]*)|(19[0,1,3-9]*))(\.[0-9]{1,3}){3}')
  # 当前网卡数据
  network_data=$(cat /proc/net/dev | grep "$NET_DRIVER")
  # 当前网卡接收流量
  in_flow=$(echo $network_data | awk '{print $2}')
  # 当前网卡发送流量
  out_flow=$(echo $network_data | awk '{print $10}')
  # 大于阈值就报警
  last_log=$(parse_last_log "network")
  last_in_flow=$(echo $last_log | awk '{print $1}')
  last_out_flow=$(echo $last_log | awk '{print $2}')
  diff_in_flow=$((( $last_in_flow > 0 )) && echo $[ $in_flow - $last_in_flow ] || echo 0)
  diff_out_flow=$((( $last_out_flow > 0 )) && echo $[ $out_flow - $last_out_flow ] || echo 0)
  # 日志数据
  log_data=`cat << EOF
当前时间 $now
监听网卡 $NET_DRIVER
接收流量 $in_flow
发送流量 $out_flow
1分钟内接收 $([[ $diff_in_flow > 0 ]] && echo $diff_in_flow | awk '{printf "%.2fm", ($1 / 1024) / 1024}' || echo 0)
1分钟内发送 $([[ $diff_out_flow > 0 ]] && echo $diff_out_flow | awk '{printf "%.2fm", ($1 / 1024) / 1024}' || echo 0)
>>外网连接
$connections
======
EOF`
  # 写入文件
  echo "$log_data" >> ${TEMP_DIR}"/network"
  # 判断是否通知
  if (( $diff_in_flow > 0 && $diff_in_flow > $MAX_FLOW_IN )) || (( $diff_out_flow > 0 && $diff_out_flow > $MAX_FLOW_OUT )); then
    # 简化参数，太长钉钉会报错
    alert_msg=`cat << EOF
$DINGTALK_KEYWORD-流量可能存在异常
$(echo "$log_data" | head -n 6)
共$(echo "$connections" | wc -l)个外网连接
EOF`
    send_notification "$alert_msg"
  fi
}

# cpu
cpu_info() {
  # cpu负载
  cpu_use=$(top -n 1 | grep %Cpu | awk -F, '{print $4}' | awk '{printf "%.1f%%", 100-$2}')
  # 占用cpu进程前5
  process_top5=$(ps -eo pid,ppid,%mem,%cpu,user,comm --sort=-%cpu | head -n 6)
  # 日志数据
  log_data=`cat << EOF
当前时间 $now
当前负载 $cpu_use
>>占用前5的进程
$process_top5
======
EOF`
  # 写入缓存
  echo "$log_data" >> ${TEMP_DIR}"/cpu"
  # 判断是否通知
  if (( ${cpu_use%%.*} >= $MAX_CPU_USE )); then
    send_notification "`echo -e "$DINGTALK_KEYWORD-cpu占用可能存在异常\n$log_data"`"
  fi
}

# 内存
memory_info() {
  # 内存占用
  memory_use=$(free -m | awk '$1 ~ /Mem/ {printf "%.2f%%",$3/$2*100}')
  # 占用cpu进程前5
  process_top5=$(ps -eo pid,ppid,%mem,%cpu,user,comm --sort=-%mem | head -n 6)
  # 日志数据
  log_data=`cat << EOF
当前时间 $now
当前负载 $memory_use
>>占用前5的进程
$process_top5
======
EOF`
  # 写入缓存
  echo "$log_data" >> ${TEMP_DIR}"/memory"
  # 判断是否通知
  if (( ${memory_use%%.*} >= $MAX_MEMORY_USE )); then
    send_notification "`echo "$DINGTALK_KEYWORD-内存占用可能存在异常\n$log_data"`"
  fi
}

cpu_info
memory_info
network_info