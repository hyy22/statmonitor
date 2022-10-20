# statmonitor

随时监测服务器cpu，内存，网络相关状态信息，存在异常自动触发报警

## 使用

### 下载代码

```bash
git clone https://github.com/hyy22/statmonitor.git
cd statmonitor
```

### 修改配置

按实际需要修改

```
# 监听网卡
NET_DRIVER=ens0
# 缓存日志目录
TEMP_DIR=/home/somebody/.statmonitor
# 阈值，超过触发报警
MAX_CPU_USE=80 # 最大cpu占用，%
MAX_MEMORY_USE=80 # 最大内存占用，%
MAX_FLOW_IN=12288000 # 最大接收流量，byte
MAX_FLOW_OUT=12288000 # 最大发送流量，byte
# 钉钉相关
DINGTALK_ACCESS_TOKEN='' # 请填写token
DINGTALK_KEYWORD='阿里云' # 触发关键词
```

### 测试

```bash
./main.sh
```

### 部署

```bash
# 添加定时任务
crontab -e
# 写入以下内容，！！需要修改目录
*/1 * * * * /home/somebody/statmonitor/main.sh
59 23 * * * /home/somebody/statmonitor/package.sh
```

## 功能

每分钟会记录当前cpu，内存，网络等相关指标到日志文件

### cpu

cpu当前占用百分比

最占cpu的进程top5

### 内存

内存当前占用百分比

最占内存的进程top5

## 网络

当前网卡进出口数据（byte）

1分钟间隔网卡进出口数据（m）

连接到当前服务器的外部ip列表