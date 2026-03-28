---
name: advise
description: 开始工作前先搜索团队知识。在开始实验、调试不熟悉的错误，或实现存在未知因素的功能之前使用。
argument-hint: <任务描述>
allowed-tools: [Read, Bash, Grep, Glob, Agent]
---

# /advise

开始工作前，先搜索技能注册表以查找相关的既有经验。

## 目标仓库

**Repository**: `CHZarles/ProjectMnemosyne`
**Clone location**: `$HOME/.agent-brain/ProjectMnemosyne/`

位于用户主目录中的单个共享克隆。会在搜索前自动更新。
如果已经在 ProjectMnemosyne 仓库中运行，则会自动跳过。

## 说明

当用户调用此命令时：

### Phase 1: 搜索并展示发现

1. **设置仓库**（如果尚未克隆）：

   ```bash
   # Detect if already in ProjectMnemosyne
   CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
   if [[ "$CURRENT_REMOTE" == *"ProjectMnemosyne"* ]] && [[ "$CURRENT_REMOTE" != *"ProjectMnemosyne-"* ]]; then
     # Already in ProjectMnemosyne - use current directory
     MNEMOSYNE_DIR="."
   else
     # Use shared home directory location
     MNEMOSYNE_DIR="$HOME/.agent-brain/ProjectMnemosyne"

     if [ ! -d "$MNEMOSYNE_DIR" ]; then
       # Clone fresh
       mkdir -p "$HOME/.agent-brain"
       gh repo clone CHZarles/ProjectMnemosyne "$MNEMOSYNE_DIR"
     fi

     # Always update to latest main before searching
     git -C "$MNEMOSYNE_DIR" fetch origin
     git -C "$MNEMOSYNE_DIR" checkout main
     git -C "$MNEMOSYNE_DIR" pull --ff-only origin main
   fi
   ```

2. 从 $ARGUMENTS 中**解析用户的目标**
3. 读取 `.claude-plugin/marketplace.json` 以查找可用插件
4. 通过以下方式**搜索匹配的插件**：
   - 优先按类别（如果用户的查询暗示了某个类别）
   - 描述关键词和触发条件
   - 标签（如果存在）
   - 选择最相关的前 5 个匹配项
5. 仅为前几项匹配读取技能 `.md` 文件（来自扁平的 `skills/<name>.md` 文件）
   - 重点关注：`## Failed Attempts`、`## When to Use`、`## Results & Parameters`

6. **CRITICAL — 对每个匹配技能进行可信度评估**：

   检查 YAML frontmatter 中的 `verification` 字段。如果不存在，则视为 `unverified`。

   对每个技能进行评分：
   - `verified-ci` = HIGH confidence — 该方法已在 CI 中端到端验证
   - `verified-local` = MEDIUM confidence — 本地可行，但 CI 可能有所不同
   - `verified-precommit` = LOW confidence — 仅检查了格式化/linting，未验证执行
   - `unverified` 或缺失 = TREAT WITH SKEPTICISM — 该方法是理论性的

   **标记矛盾之处**：如果两个技能针对同一主题给出了冲突建议，需高亮显示
   两者，并说明哪一个更新/验证更充分。例如：“Skill A 建议重试 JIT 崩溃，
   但更新的 Skill B（verified-ci）指出它们实际上是编译错误。”

7. **CRITICAL — 检查历史文件**：

   对于每个匹配的技能，检查是否存在 `.history` 文件：

   ```bash
   ls "$MNEMOSYNE_DIR/skills/<name>.history" 2>/dev/null
   ```

   如果存在历史文件，请检查版本并读取变更日志标题，以了解
   该技能是如何演变的。一个带有丰富历史的 v3.0.0 技能说明它经历过实战检验
   并被多次修订——它比 v1.0.0 的技能更值得信赖。

   在展示发现时，请注明版本：
   - `v1.0.0` = 初始版本，可能尚未经过打磨
   - `v2.0.0+` = 至少修订过一次，包含历史日志，展示了变更内容及原因
   - 具有历史文件且显示先前方法有误的技能尤其有价值——
     它们记录了从错误到正确的演进过程

   如果历史文件显示该技能与其早期版本自相矛盾，请高亮指出：

   > **Evolution note:** 该技能已从 v1.0.0（推荐 X）修订为 v2.0.0
   > （改为推荐 Y）。历史日志解释了为什么 X 不起作用。

8. **展示发现**，并带上可信度标记：
   - 什么有效（已验证的方法）——附验证级别和版本
   - 什么失败了（关键——可避免浪费精力）
   - 历史文件中的演进说明（如果有）
   - 推荐参数（可直接复制粘贴）

### Phase 2: 后续跟进（如有需要）

展示发现后，询问：
“Would you like me to dig deeper into any of these skills, or are you ready to proceed?”

如果用户想要更多细节，请读取最相关匹配项的完整技能 `.md` 文件
及其 `.history` 文件。

> **注意**：如果用户的目标涉及**创建或修复技能**，提醒他们运行
> `/learn`，它会捕获会话中的经验并创建或修订技能文件。

## 输出格式

```markdown
### Related Skills Found

| Skill      | Version | Verification | Relevance                            |
| ---------- | ------- | ------------ | ------------------------------------ |
| skill-name | v2.0.0  | verified-ci  | Why relevant                         |
| skill-name | v1.0.0  | unverified   | Why relevant (TREAT WITH SKEPTICISM) |

### Evolution Notes

> **skill-name** was amended from v1.0.0 → v2.0.0 on YYYY-MM-DD.
> v1.0.0 recommended using `check_gradients()` with absolute tolerance.
> v2.0.0 switched to `check_gradient()` with relative+absolute tolerance
> because absolute tolerance fails for large-magnitude gradients.
> [Full history](skills/skill-name.history)

### Key Findings

**What Worked** (high confidence):

- Verified approach 1 [verified-ci, v2.0.0]
- Verified approach 2 [verified-local, v1.0.0]

**What Worked** (low confidence — verify before using):

- Approach 3 [verified-precommit only, v1.0.0]

**What Failed** (Critical!):

- Failed approach 1: Why it failed
- Failed approach 2: Why it failed (documented in v1.0.0 → v2.0.0 amendment)

**Recommended Parameters**:
\`\`\`yaml
param1: value1
\`\`\`

**Need more detail?** Ask me to read the full SKILL.md or its .history for any skill above.
```

## 示例工作流

### 调用

```bash
/hephaestus:advise training a model with GRPO
```

### 输出

```markdown
### Related Skills Found

| Skill              | Version | Verification   | Relevance                                   |
| ------------------ | ------- | -------------- | ------------------------------------------- |
| grpo-external-vllm | v2.0.0  | verified-ci    | Uses external vLLM server for GRPO training |
| grpo-batch-tuning  | v1.0.0  | verified-local | Optimal batch sizes for GRPO                |

### Evolution Notes

> **grpo-external-vllm** was amended from v1.0.0 → v2.0.0 on 2026-02-15.
> v1.0.0 used same-GPU vLLM which caused OOM. v2.0.0 uses separate GPU.
> [Full history](skills/grpo-external-vllm.history)

### Key Findings

**What Worked** (high confidence):

- External vLLM server prevents memory issues [verified-ci, v2.0.0]
- batch_size=4 with learning_rate=1e-5 for 7B models [verified-ci]

**What Failed** (Critical!):

- vllm_skip_weight_sync errors when vLLM on same GPU (fixed in v2.0.0)
- batch_size > 8 causes OOM on 24GB GPUs
- learning_rate > 5e-5 causes training instability

**Need more detail?** Ask me to read the full SKILL.md or its .history for any skill above.
```
