#!/bin/bash
# 每日学习内容生成脚本

set -e

# 配置
REPO_DIR="/usr/local/github/SolidityLearning"
PLAN_FILE="$REPO_DIR/learning_plan.json"
CURRENT_DATE=$(date +%Y-%m-%d)
CHINA_DATE=$(TZ=Asia/Shanghai date +%Y-%m-%d)

echo "=== 每日学习内容生成脚本执行于 $(date) ==="
echo "当前日期: $CURRENT_DATE"
echo "北京时间: $CHINA_DATE"

# 检查计划文件
if [ ! -f "$PLAN_FILE" ]; then
    echo "错误: 学习计划文件不存在: $PLAN_FILE"
    exit 1
fi

# 使用Python解析JSON（如果可用）或者使用简单方法
if command -v python3 &> /dev/null; then
    # 使用Python解析
    DAY_INFO=$(python3 -c "
import json, sys, datetime
with open('$PLAN_FILE', 'r') as f:
    plan = json.load(f)
start_date = datetime.datetime.strptime(plan['start_date'], '%Y-%m-%d').date()
current_date = datetime.datetime.strptime('$CHINA_DATE', '%Y-%m-%d').date()
day_num = (current_date - start_date).days + 1
if day_num < 1 or day_num > len(plan['plan']):
    print('')
    sys.exit(1)
day_plan = plan['plan'][day_num-1]
print(f'{day_num}|{day_plan[\"title\"]}|{day_plan[\"lessons\"][0]}-{day_plan[\"lessons\"][-1]}')
for i, topic in enumerate(day_plan['topics']):
    print(f'topic{i+1}:{topic}')
for i, item in enumerate(day_plan['homework']['practice']):
    print(f'hw_practice{i+1}:{item}')
for i, item in enumerate(day_plan['homework']['thinking']):
    print(f'hw_thinking{i+1}:{item}')
for i, item in enumerate(day_plan['homework']['summary']):
    print(f'hw_summary{i+1}:{item}')
" 2>/dev/null || echo "")
    
    if [ -z "$DAY_INFO" ]; then
        echo "错误: 无法解析学习计划或日期超出范围"
        exit 1
    fi
    
    # 解析Python输出
    DAY_NUM=$(echo "$DAY_INFO" | grep '^[0-9]\+|' | cut -d'|' -f1)
    DAY_TITLE=$(echo "$DAY_INFO" | grep '^[0-9]\+|' | cut -d'|' -f2)
    DAY_LESSONS=$(echo "$DAY_INFO" | grep '^[0-9]\+|' | cut -d'|' -f3)
    
    # 提取主题
    TOPICS=()
    for i in {1..10}; do
        TOPIC=$(echo "$DAY_INFO" | grep "^topic$i:" | cut -d':' -f2-)
        [ -n "$TOPIC" ] && TOPICS+=("$TOPIC")
    done
    
    # 提取作业
    HW_PRACTICE=()
    for i in {1..5}; do
        ITEM=$(echo "$DAY_INFO" | grep "^hw_practice$i:" | cut -d':' -f2-)
        [ -n "$ITEM" ] && HW_PRACTICE+=("$ITEM")
    done
    
    HW_THINKING=()
    for i in {1..5}; do
        ITEM=$(echo "$DAY_INFO" | grep "^hw_thinking$i:" | cut -d':' -f2-)
        [ -n "$ITEM" ] && HW_THINKING+=("$ITEM")
    done
    
    HW_SUMMARY=()
    for i in {1..5}; do
        ITEM=$(echo "$DAY_INFO" | grep "^hw_summary$i:" | cut -d':' -f2-)
        [ -n "$ITEM" ] && HW_SUMMARY+=("$ITEM")
    done
    
else
    # 如果没有Python，使用简单方法（仅支持第一天）
    if [ "$CHINA_DATE" = "2026-04-13" ]; then
        DAY_NUM=1
        DAY_TITLE="介绍、环境、第一个合约"
        DAY_LESSONS="1-4"
        TOPICS=("什么是Solidity？" "开发环境搭建" "第一个智能合约" "合约交互")
        HW_PRACTICE=("在Remix中部署一个'Hello World'合约" "编译并调用合约函数")
        HW_THINKING=("智能合约与传统程序的根本区别是什么？" "为什么区块链需要智能合约？")
        HW_SUMMARY=("总结智能合约的核心价值" "解释区块链与智能合约的关系")
    else
        echo "错误: 需要Python3来解析学习计划"
        exit 1
    fi
fi

echo "学习第 $DAY_NUM 天: $DAY_TITLE"
echo "课程: 第 $DAY_LESSONS 讲"

# 创建当日学习文件夹
LEARN_DIR="$REPO_DIR/学习内容-$CHINA_DATE"
mkdir -p "$LEARN_DIR"
echo "创建学习目录: $LEARN_DIR"

# 创建markdown文档
MD_FILE="$LEARN_DIR/README.md"
cat > "$MD_FILE" << EOF
# 第 $DAY_NUM 天学习内容 ($CHINA_DATE)

## 📚 今日学习大纲
**主题:** $DAY_TITLE  
**课程范围:** WTF-Solidity 第 $DAY_LESSONS 讲

### 主要内容
$(
for i in "${!TOPICS[@]}"; do
  echo "$((i+1)). **${TOPICS[$i]}**"
done
)

## 📝 今日作业

### 实践题
$(
for i in "${!HW_PRACTICE[@]}"; do
  echo "$((i+1)). ${HW_PRACTICE[$i]}"
done
)

### 思考题
$(
for i in "${!HW_THINKING[@]}"; do
  echo "$((i+1)). ${HW_THINKING[$i]}"
done
)

### 总结题
$(
for i in "${!HW_SUMMARY[@]}"; do
  echo "$((i+1)). ${HW_SUMMARY[$i]}"
done
)

## 🔗 学习资源
- **WTF-Solidity主仓库:** https://github.com/WTFAcademy/WTF-Solidity
- **Remix在线编辑器:** https://remix.ethereum.org
- **你的学习仓库:** https://github.com/2173368/SolidityLearning

## 📌 学习建议
1. 先快速浏览今日课程，建立整体印象
2. 按步骤实际操作，理解每个概念
3. 完成作业，巩固知识点
4. 记录学习心得和遇到的问题

---

*本文档基于学习计划自动生成，具体内容请参考WTF-Solidity官方教程。*  
*生成时间: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

echo "创建Markdown文档: $MD_FILE"

# 4. 提交到git
cd "$REPO_DIR"
git add .
if git diff --cached --quiet; then
    echo "没有变化需要提交"
else
    git commit -m "添加第 $DAY_NUM 天学习内容 ($CHINA_DATE)"
    echo "已提交到git"
fi

echo "=== 脚本执行完成 ==="
echo "学习目录: $LEARN_DIR"
echo "文档: $MD_FILE"