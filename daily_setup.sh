#!/bin/bash
# 每日学习内容设置脚本
# 在每天8:30（北京时间）执行

set -e

# 配置
REPO_DIR="/usr/local/github/SolidityLearning"
WTFSOLIDITY_DIR="/tmp/wtf-solidity"
CURRENT_DATE=$(date +%Y-%m-%d)
CHINA_DATE=$(TZ=Asia/Shanghai date +%Y-%m-%d)
DAY_NUM=$(( ( $(date -d "$CURRENT_DATE" +%s) - $(date -d "2026-04-13" +%s) ) / 86400 + 1 ))

echo "=== 每日学习设置脚本执行于 $(date) ==="
echo "当前日期: $CURRENT_DATE"
echo "北京时间: $CHINA_DATE"
echo "学习第 $DAY_NUM 天"

# 1. 拉取WTF-Solidity最新代码（如果存在）
if [ -d "$WTFSOLIDITY_DIR/.git" ]; then
    echo "拉取WTF-Solidity更新..."
    cd "$WTFSOLIDITY_DIR"
    git pull origin main 2>/dev/null || true
else
    echo "克隆WTF-Solidity仓库..."
    rm -rf "$WTFSOLIDITY_DIR"
    git clone --depth 1 https://github.com/WTFAcademy/WTF-Solidity.git "$WTFSOLIDITY_DIR" 2>/dev/null || true
fi

# 2. 创建当日学习文件夹
LEARN_DIR="$REPO_DIR/学习内容-$CHINA_DATE"
mkdir -p "$LEARN_DIR"
echo "创建学习目录: $LEARN_DIR"

# 3. 创建markdown文档
MD_FILE="$LEARN_DIR/README.md"
cat > "$MD_FILE" << EOF
# 第 $DAY_NUM 天学习内容 ($CHINA_DATE)

## 学习大纲

根据学习计划，今日应学习 WTF-Solidity 第 $(( (DAY_NUM-1)*4 + 1 ))-$(( DAY_NUM*4 )) 讲。

### 主要内容
1. **待补充** - 请参考WTF-Solidity官方教程
2. **待补充** - 请参考WTF-Solidity官方教程  
3. **待补充** - 请参考WTF-Solidity官方教程
4. **待补充** - 请参考WTF-Solidity官方教程

## 今日作业

### 实践题
1. 完成今日教程中的代码练习
2. 在Remix中部署并测试合约

### 思考题
1. 总结今日学习的核心概念
2. 分析这些概念在实际应用中的重要性

### 总结题
1. 用你自己的话解释今日学习的知识点
2. 思考这些知识如何应用到实际项目中

## 学习资源
- WTF-Solidity主仓库: https://github.com/WTFAcademy/WTF-Solidity
- Remix在线编辑器: https://remix.ethereum.org
- 你的学习仓库: https://github.com/2173368/SolidityLearning

*注：此文档为自动生成，具体内容请参考WTF-Solidity官方教程。*
EOF

echo "创建Markdown文档: $MD_FILE"

# 4. 提交到git
cd "$REPO_DIR"
git add .
git commit -m "添加第 $DAY_NUM 天学习内容 ($CHINA_DATE)" 2>/dev/null || true

echo "=== 脚本执行完成 ==="
echo "请检查目录: $LEARN_DIR"
echo "文档: $MD_FILE"