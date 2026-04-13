#!/bin/bash
# 每日学习内容生成脚本（增强版）
# 错误处理和状态报告功能

# 配置
STATUS_DIR="/tmp/solidity_learning"
mkdir -p "$STATUS_DIR"
STATUS_FILE="$STATUS_DIR/status_$(TZ=Asia/Shanghai date +%Y-%m-%d).txt"
SUMMARY_FILE="$STATUS_DIR/summary_$(TZ=Asia/Shanghai date +%Y-%m-%d).txt"

# 清理旧的状态文件（保留最近3天）
find "$STATUS_DIR" -name "status_*.txt" -mtime +3 -delete 2>/dev/null || true
find "$STATUS_DIR" -name "summary_*.txt" -mtime +3 -delete 2>/dev/null || true

# 初始化状态文件
echo "执行时间: $(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S')" > "$STATUS_FILE"
echo "状态: 执行中" >> "$STATUS_FILE"

# 错误处理函数
handle_error() {
    local exit_code=$?
    local error_msg="$1"
    echo "状态: 失败" >> "$STATUS_FILE"
    echo "错误代码: $exit_code" >> "$STATUS_FILE"
    echo "错误信息: $error_msg" >> "$STATUS_FILE"
    echo "失败时间: $(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S')" >> "$STATUS_FILE"
    echo "=== 脚本执行失败 ===" >&2
    exit $exit_code
}

# 成功处理函数
handle_success() {
    echo "状态: 成功" >> "$STATUS_FILE"
    echo "完成时间: $(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S')" >> "$STATUS_FILE"
    echo "学习目录: $LEARN_DIR" >> "$STATUS_FILE"
    echo "文档: $MD_FILE" >> "$STATUS_FILE"
    echo "=== 脚本执行成功 ===" >&2
}

# 设置错误捕获
trap 'handle_error "脚本执行出错"' ERR

# 配置
REPO_DIR="/usr/local/github/SolidityLearning"
PLAN_FILE="$REPO_DIR/learning_plan.json"
WTFSOLIDITY_DIR="/tmp/wtf-solidity"
CURRENT_DATE=$(date +%Y-%m-%d)
CHINA_DATE=$(TZ=Asia/Shanghai date +%Y-%m-%d)

echo "=== 每日学习内容生成脚本执行于 $(date) ===" >&2
echo "当前日期: $CURRENT_DATE" >&2
echo "北京时间: $CHINA_DATE" >&2

# 0. 拉取用户仓库最新代码
echo "拉取用户仓库最新代码..." >&2
cd "$REPO_DIR"
git pull origin main 2>/dev/null || echo "拉取用户仓库失败，继续执行" >&2

# 1. 尝试拉取WTF-Solidity最新代码
echo "尝试拉取WTF-Solidity最新代码..." >&2
if [ -d "$WTFSOLIDITY_DIR/.git" ]; then
    cd "$WTFSOLIDITY_DIR"
    git pull origin main --depth 1 2>/dev/null || echo "拉取更新失败，使用缓存内容" >&2
else
    echo "克隆WTF-Solidity仓库（浅克隆）..." >&2
    rm -rf "$WTFSOLIDITY_DIR"
    git clone --depth 1 https://github.com/WTFAcademy/WTF-Solidity.git "$WTFSOLIDITY_DIR" 2>/dev/null || echo "克隆失败，继续使用计划文件" >&2
fi

# 2. 解析学习计划
if [ ! -f "$PLAN_FILE" ]; then
    echo "错误: 学习计划文件不存在: $PLAN_FILE" >&2
    exit 1
fi

# 使用Python解析JSON
if ! command -v python3 &> /dev/null; then
    echo "错误: 需要Python3来解析学习计划" >&2
    exit 1
fi

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
    echo "错误: 无法解析学习计划或日期超出范围" >&2
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

echo "学习第 $DAY_NUM 天: $DAY_TITLE" >&2
echo "课程: 第 $DAY_LESSONS 讲" >&2

# 3. 创建当日学习文件夹
LEARN_DIR="$REPO_DIR/WTF-Solidity-${DAY_LESSONS}讲-$CHINA_DATE"
mkdir -p "$LEARN_DIR"
echo "创建学习目录: $LEARN_DIR" >&2

# 4. 创建markdown文档
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

echo "创建Markdown文档: $MD_FILE" >&2

# 5. 提交到git
cd "$REPO_DIR"
git add .
if git diff --cached --quiet; then
    echo "没有变化需要提交" >&2
else
    git commit -m "添加第 $DAY_NUM 天学习内容 ($CHINA_DATE)"
    echo "已提交到git" >&2
    # 推送到远程仓库
    git push origin main 2>/dev/null && echo "已推送到GitHub" >&2 || echo "推送失败" >&2
fi

# 6. 创建完成标志文件
echo "$CHINA_DATE:$DAY_NUM:$DAY_TITLE" > "/tmp/solidity_learning_done_$CHINA_DATE.txt"

echo "=== 脚本执行完成 ===" >&2
echo "学习目录: $LEARN_DIR" >&2
echo "文档: $MD_FILE" >&2

# 7. 生成摘要文件供提醒使用
if [ -f "$MD_FILE" ]; then
    # 提取关键信息
    {
        echo "📚 今日Solidity学习内容摘要"
        echo "日期: $CHINA_DATE"
        echo "学习天数: 第 $DAY_NUM 天"
        echo "主题: $DAY_TITLE"
        echo "课程范围: WTF-Solidity 第 $DAY_LESSONS 讲"
        echo ""
        echo "📖 主要知识点:"
        for i in "${!TOPICS[@]}"; do
            echo "$((i+1)). ${TOPICS[$i]}"
        done
        echo ""
        echo "📝 实践作业:"
        for i in "${!HW_PRACTICE[@]}"; do
            echo "$((i+1)). ${HW_PRACTICE[$i]}"
        done
        echo ""
        echo "💭 思考题:"
        for i in "${!HW_THINKING[@]}"; do
            echo "$((i+1)). ${HW_THINKING[$i]}"
        done
        echo ""
        echo "🔗 学习资源:"
        echo "- WTF-Solidity主仓库: https://github.com/WTFAcademy/WTF-Solidity"
        echo "- 你的学习仓库: https://github.com/2173368/SolidityLearning"
    } > "$SUMMARY_FILE"
    echo "已生成摘要文件: $SUMMARY_FILE" >&2
fi

# 8. 记录成功状态
handle_success