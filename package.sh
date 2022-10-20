#!/bin/bash
:<< EOF
按日期打包备份文件
59 23 * * * package.sh
@params $1 备份文件夹
@params $2 是否删除原文件，默认1删除，0不删除
EOF

set -e
# 引入配置
source `dirname $0`/config.sh
# 打包文件夹
target_dir=${1:-"$TEMP_DIR"}
# 是否删除原文件
is_delete=${2:-1}
# 压缩文件名
tar_name=${target_dir##*/}
# -P绝对路径需要加
tar --exclude="${target_dir}/*.gz" \
  --wildcards \
  `(( $is_delete == 1 )) && echo '--remove-files' || echo ''` \
  -Pczf ${target_dir}/${tar_name}_`date +%F`.tar.gz ${target_dir}/*