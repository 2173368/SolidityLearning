#!/bin/bash
# 模拟明天的日期运行学习脚本

# 设置明天的日期（北京时间）
export CHINA_DATE="2026-04-14"

# 修改环境变量，让脚本使用我们设置的日期
# 我们需要修改脚本内部的日期计算
cd /usr/local/github/SolidityLearning

# 创建临时脚本副本
cp daily_learning_v2.sh daily_learning_test.sh

# 修改脚本中的日期计算部分
sed -i 's/CHINA_DATE=\$(TZ=Asia\/Shanghai date +%Y-%m-%d)/CHINA_DATE="2026-04-14"/' daily_learning_test.sh
sed -i 's/STATUS_FILE="\$STATUS_DIR\/status_\$(TZ=Asia\/Shanghai date +%Y-%m-%d).txt"/STATUS_FILE="\$STATUS_DIR\/status_2026-04-14.txt"/' daily_learning_test.sh
sed -i 's/SUMMARY_FILE="\$STATUS_DIR\/summary_\$(TZ=Asia\/Shanghai date +%Y-%m-%d).txt"/SUMMARY_FILE="\$STATUS_DIR\/summary_2026-04-14.txt"/' daily_learning_test.sh

# 运行测试脚本
echo "=== 模拟明天（2026-04-14）的学习内容生成 ==="
bash daily_learning_test.sh

# 检查生成的文件
echo ""
echo "=== 检查生成的文件 ==="
ls -la /tmp/solidity_learning/

echo ""
echo "=== 摘要文件内容 ==="
if [ -f "/tmp/solidity_learning/summary_2026-04-14.txt" ]; then
    cat "/tmp/solidity_learning/summary_2026-04-14.txt"
else
    echo "摘要文件未生成"
fi

# 清理临时文件
rm -f daily_learning_test.sh