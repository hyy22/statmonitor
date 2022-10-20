#!/bin/bash
# 监听网卡
NET_DRIVER=ens0
# 缓存日志目录，！！请修改日志目录
TEMP_DIR=/home/somebody/.statmonitor
# 阈值，超过触发报警
MAX_CPU_USE=80 # 最大cpu占用，%
MAX_MEMORY_USE=80 # 最大内存占用，%
MAX_FLOW_IN=12288000 # 最大接收流量，byte
MAX_FLOW_OUT=12288000 # 最大发送流量，byte
# 钉钉相关
DINGTALK_ACCESS_TOKEN='' # ！！请填写token
DINGTALK_KEYWORD='阿里云' # 触发关键词