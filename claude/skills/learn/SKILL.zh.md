---
name: learn
description: 将会话经验保存为新的技能插件。用于实验之后、调试会话之后，或当你想要保留团队知识时使用。
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# /learn

捕获会话经验，并在 ProjectMnemosyne 市场中创建或修订一个技能文件。

## 目标仓库

**仓库**: `CHZarles/ProjectMnemosyne`
**基础分支**: `main`
**克隆位置**: `$HOME/.agent-brain/ProjectMnemosyne/`

位于用户主目录中的单个共享克隆。创建 PR 后会自动清理。
如果已经在 ProjectMnemosyne 仓库中运行，则自动跳过。

## 说明

当用户调用此命令时：

1. **分析对话** 以提取：
   - 目标：用户试图完成什么？
   - 已采取的步骤：尝试了哪些方法？
   - 成功之处：什么有效？
   - 失败之处：什么无效，为什么？
   - 参数：使用了哪些配置/设置？

2. **自动生成技能元数据**（不要向用户提问）：
   - 分析对话主题以提取：`<topic>-<subtopic>`
   - 从关键经验中生成简短的 4 词摘要
   - 文件名：`<topic>-<subtopic>-<short-4-word-summary>`（kebab-case）
   - 从对话上下文中自动检测类别（training、evaluation、optimization、debugging、architecture、tooling、ci-cd、testing、documentation）

3. **关键 —— 搜索可修订的现有技能**：

   在创建新文件之前，搜索注册表中涵盖相同主题的技能：

   ```bash
   MNEMOSYNE_DIR="$HOME/.agent-brain/ProjectMnemosyne"
   # Search by keywords from the skill name
   ls "$MNEMOSYNE_DIR/skills/" | grep -i "<keyword1>\|<keyword2>\|<keyword3>" | grep -v ".notes.md" | grep -v ".history"
   # Also search descriptions in frontmatter
   grep -l "<keyword>" "$MNEMOSYNE_DIR/skills/"*.md 2>/dev/null | head -20
   ```

   **如果现有技能涵盖相同主题 → 修订它**（不要创建新文件）：

   a. 读取现有技能以了解其当前状态  
   b. 将当前版本归档到历史日志中（见第 4 步）  
   c. 就地更新技能 `.md` 文件，加入新的经验：
   - 在表格中添加新的 Failed Attempts 行
   - 如果方法已更改，则更新 Verified Workflow
   - 用新数据更新 Results & Parameters
   - 使用**语义化版本控制**提升 `version`（见下表）
   - 将 `date` 更新为今天

   **技能修订的语义化版本规则：**

   | Change Type       | Bump              | When to Use                                    | Examples                                               |
   | ----------------- | ----------------- | ---------------------------------------------- | ------------------------------------------------------ |
   | **Major** (X.0.0) | `1.0.0` → `2.0.0` | 合并多个技能、重写已验证工作流、改变核心推荐   | 合并 5 个重复技能；替换推荐 API                        |
   | **Minor** (0.X.0) | `1.0.0` → `1.1.0` | 添加新发现、新的失败尝试、通过新步骤扩展工作流 | 添加 2 行 Failed Attempts；新增 “When to Use” 触发条件 |
   | **Patch** (0.0.X) | `1.0.0` → `1.0.1` | 修正拼写错误、格式、元数据更正、澄清现有文本   | 修正 category 拼写错误；修复损坏的 markdown 表格       |

   d. 更新历史文件中的变更日志

   **如果没有匹配的现有技能 → 创建新技能**（继续执行第 5 步）

4. **历史日志管理**（用于修订）：

   修订现有技能时，在 `skills/<name>.history` 中保留先前版本：

   **文件：`skills/<name>.history`**

   这是一个仅追加日志。每个条目记录更改了什么以及为什么更改。格式如下：

   ```markdown
   # <skill-name> — History

   ## v2.0.0 (YYYY-MM-DD)

   **Changed by:** Session context (e.g., "PR #5107 gradient checking fixes")
   **Verification:** verified-ci | verified-local | verified-precommit | unverified

   ### What changed

   - Updated tolerance from 1e-2 absolute to rtol=1e-2 + atol=1e-2 combined
   - Added check_gradient() as preferred API over check_gradients()
   - Added 2 new Failed Attempts entries

   ### Why

   Previous approach (v1.0.0) used check_gradients() with absolute tolerance.
   CI showed this fails for multi-channel conv2d where gradient magnitudes reach ~32-126.
   Relative tolerance via check_gradient() handles large magnitudes correctly.

   ### Previous version (v1.0.0) snapshot

   <paste the full previous skill content here as a reference>

   ---

   ## v1.0.0 (YYYY-MM-DD)

   **Initial version.**
   ```

   **历史文件规则：**
   - 在顶部追加新条目（最新的在最前）
   - 始终包含：版本、日期、更改内容、原因、之前的快照
   - 快照保留精确的先前内容，以确保可审计性
   - 从主技能文件添加一个引用：`**History:** [changelog](./skills/<name>.history)`

5. **关键 —— “Verified Workflow”的诚实性门槛**：

   在编写 “Verified Workflow” 部分之前，诚实地回答以下问题：
   - 工作流是否真的端到端执行过？（不只是 pre-commit hooks —— 而是真实的测试/代码）
   - CI 是否在这些更改下通过？如果没有，该部分**必须**命名为 “Proposed Workflow” 而不是 “Verified Workflow”
   - 结果是在 CI 中观察到的，还是仅在本地？如果仅在本地，请写明：“Verified locally only — CI validation pending”

   **验证级别**（必须在技能中注明）：
   - `verified-ci`：测试在 CI 中通过（最高置信度）
   - `verified-local`：测试在本地通过，但未在 CI 中确认
   - `verified-precommit`：只有 pre-commit hooks 通过（格式化、linting）
   - `unverified`：方法在理论上合理，但从未执行过

   将此添加为 frontmatter 字段：

   ```yaml
   verification: verified-ci | verified-local | verified-precommit | unverified
   ```

6. **设置仓库**：

   ```bash
   # Detect if already in ProjectMnemosyne
   CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
   if [[ "$CURRENT_REMOTE" == *"ProjectMnemosyne"* ]] && [[ "$CURRENT_REMOTE" != *"ProjectMnemosyne-"* ]]; then
     # Already in ProjectMnemosyne - work in current directory
     MNEMOSYNE_DIR="."
     NEED_CLEANUP=false
   else
     # Use shared home directory location
     MNEMOSYNE_DIR="$HOME/.agent-brain/ProjectMnemosyne"
     NEED_CLEANUP=true

     if [ ! -d "$MNEMOSYNE_DIR" ]; then
       # Clone fresh
       mkdir -p "$HOME/.agent-brain"
       gh repo clone CHZarles/ProjectMnemosyne "$MNEMOSYNE_DIR"
     fi

     # Always update to latest main before starting
     git -C "$MNEMOSYNE_DIR" fetch origin
     git -C "$MNEMOSYNE_DIR" checkout main
     git -C "$MNEMOSYNE_DIR" pull --ff-only origin main

     cd "$MNEMOSYNE_DIR"
   fi

   # Create branch from origin/main (clean state)
   git checkout -b skill/<name> origin/main
   ```

7. **生成或修订技能文件**，以扁平形式放在 `skills/<name>.md`：

   > 新的扁平格式：位于 `skills/` 根目录中的单个 `.md` 文件（不是嵌套目录，也不是 plugin.json）

   **文件 1：`skills/<name>.md`**，包含**YAML frontmatter + markdown 正文**：

   ````yaml
   ---
   name: <skill-name>
   description: "对该技能教授内容的简要描述。使用场景：(1) trigger1, (2) trigger2。"
   category: <category>
   date: YYYY-MM-DD
   version: "1.0.0"
   user-invocable: false
   verification: <verified-ci|verified-local|verified-precommit|unverified>
   history: <name>.history  # 仅当技能已被修订时才存在
   tags: []
   ---

   # Skill Title

   ## Overview

   | Field | Value |
   |-------|-------|
   | **Date** | YYYY-MM-DD |
   | **Objective** | 该技能开发出来是为了完成什么？ |
   | **Outcome** | 它成功了吗？可操作吗？ |
   | **Verification** | verified-ci / verified-local / verified-precommit / unverified |
   | **History** | [changelog](./<name>.history) |

   ## When to Use

   - Trigger condition 1
   - Trigger condition 2

   ## Verified Workflow

   ### Quick Reference

   ```bash
   # Copy-paste ready commands
   command --flag value
   ````

   ### Detailed Steps
   1. Step 1 description
   2. Step 2 description

   ## Failed Attempts

   | Attempt   | What Was Tried | Why It Failed | Lesson Learned |
   | --------- | -------------- | ------------- | -------------- |
   | Attempt 1 | Description    | Why failed    | Lesson         |

   ## Results & Parameters

   [Copy-paste ready configs and expected outputs]

   ## Verified On

   | Project     | Context         | Details                              |
   | ----------- | --------------- | ------------------------------------ |
   | ProjectName | Session context | [notes.md](./skills/<name>.notes.md) |

   ```

   规则：
   - 文件名：小写 kebab-case（`^[a-z0-9-]+$`）—— 例如，`training-grpo-external-vllm-setup.md`
   - `category`：9 个有效类别之一（没有 "refactoring" —— 使用 "architecture"）
   - frontmatter 中所有必填字段：name、description、category、date、version、verification
   - 所有必需的 markdown 部分：Overview、When to Use、Verified Workflow、Failed Attempts、Results & Parameters
   - **如果 verification 是 `unverified` 或 `verified-precommit`**：将该部分重命名为 “Proposed Workflow” 而不是 “Verified Workflow”，并添加警告：`> **Warning:** This workflow has not been validated end-to-end. Treat as a hypothesis until CI confirms.`

   **文件 2：`skills/<name>.notes.md`**（可选）：
   - 原始会话细节、代码片段、调试日志
   - 人类可读的参考材料
   - 仅在主技能文件之外还需要额外上下文时创建

   **文件 3：`skills/<name>.history`**（首次修订时创建）：
   - 仅追加的变更日志，带有版本快照
   - 通过 `history` frontmatter 字段从主技能文件中引用
   - 格式见第 4 步

   ```

8. **验证技能**（提交前必须通过）：

   ### Pre-Commit 验证清单

   在运行 `validate_plugins.py` 之前，确认：

   | #   | Check                                                                                                                        | Error If Missing                                 |
   | --- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
   | 1   | 技能位于 `skills/<name>.md`（扁平，而非嵌套）                                                                                | 文件位置错误                                     |
   | 2   | YAML frontmatter 以 `---` 开始                                                                                               | "missing YAML frontmatter"                       |
   | 3   | Frontmatter 包含：name、description、category、date、version                                                                 | "Missing required field: X"                      |
   | 4   | `category` 属于以下之一：training、evaluation、optimization、debugging、architecture、tooling、ci-cd、testing、documentation | "Invalid category"                               |
   | 5   | Markdown 具有全部 5 个部分：Overview、When to Use、Verified Workflow、Failed Attempts、Results & Parameters                  | "Missing required section"                       |
   | 6   | `## Failed Attempts` 具有使用竖线分隔的表格                                                                                  | "Failed Attempts table missing required columns" |
   | 7   | `## Quick Reference` 是子节 `### Quick Reference`（位于 Verified Workflow 之下）                                             | "Quick Reference should use ###"                 |

   ```bash
   python3 scripts/validate_plugins.py
   ```

   如果验证失败，修复错误并重新运行。通过前**不要**提交。

9. **提交并推送**：
   ```bash
   # For new skills:
   git add skills/<name>.md skills/<name>.notes.md 2>/dev/null || true
   git commit -m "feat: add <name> skill
   ```

Documents <brief description of what was learned>.

Verification: <verified-ci|verified-local|verified-precommit|unverified>

Key learnings:

- <bullet 1>
- <bullet 2>
- <bullet 3>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

# For amendments:

git add skills/<name>.md skills/<name>.history skills/<name>.notes.md 2>/dev/null || true
git commit -m "feat: amend <name> skill (v<X.0.0>)

<Brief description of what changed and why>.

Verification: <level>
Previous version archived in <name>.history

Key changes:

- <change 1>
- <change 2>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

git push -u origin skill/<name>

````

10. **创建 PR**（仅当推送成功时）：
 ```bash
 gh pr create --repoCHZarles/ProjectMnemosyne --base main \
   --title "feat: <add|amend> <name> skill" \
   --body "## Summary

<New skill | Amends existing skill from v<old> to v<new>>.

Documents <brief description of what was learned>.

- <Key point 1>
- <Key point 2>
- <Key point 3>

## Verification Level

**<verified-ci|verified-local|verified-precommit|unverified>**

<If not verified-ci, explain what is pending>

## Key Findings

**What Worked**:
- <Successful approach 1>
- <Successful approach 2>

**What Failed**:
- <Failed attempt 1> → <Why it failed>

## Test Plan

- [ ] Validate with \`python3 scripts/validate_plugins.py\`
- [ ] Verify skill appears in marketplace
- [ ] Test skill discovery with relevant keywords

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

 # Enable auto-merge so the PR merges automatically once CI passes
 # Note: gh pr merge requires a PR number when using --repo
 PR_NUMBER=$(gh pr list --repoCHZarles/ProjectMnemosyne --head "skill/<name>" --json number --jq '.[0].number')
 gh pr merge "$PR_NUMBER" --auto --rebase --repoCHZarles/ProjectMnemosyne
 ```

11. **清理**（如果克隆到了 $HOME/.agent-brain）：
 ```bash
 if [ "$NEED_CLEANUP" = true ]; then
   # After PR created, remove the worktree clone
   rm -rf "$HOME/.agent-brain/ProjectMnemosyne"
 fi
 ```

## 修订工作流摘要

```text
Existing skill found?
├─ YES → Amend workflow:
│   1. Read existing skill
│   2. Create/append to <name>.history with previous version snapshot
│   3. Update <name>.md in-place (new data, bump version, update date)
│   4. Add history frontmatter field if first amendment
│   5. Commit both files
│
└─ NO → New skill workflow:
 1. Create <name>.md with full template
 2. Optionally create <name>.notes.md
 3. No history file needed yet
 4. Commit
````

## 常见问题与解决方案

### 主要验证失败项

| Error                                            | Cause                                      | Fix                                                                                                               |
| ------------------------------------------------ | ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| "Missing required field: X"                      | Frontmatter 缺少某个字段                   | 将字段添加到 YAML 中：name、description、category、date、version                                                  |
| "Invalid category"                               | Category 不在批准列表中                    | 使用以下之一：training、evaluation、optimization、debugging、architecture、tooling、ci-cd、testing、documentation |
| "missing YAML frontmatter"                       | 文件不是以 `---` 开始                      | 在文件最顶部、元数据之前添加 `---`                                                                                |
| "Missing required section: X"                    | 缺少 Overview/When/Workflow/Failed/Results | 使用 `##` 标题添加全部 5 个部分                                                                                   |
| "Failed Attempts table missing required columns" | 表格格式不正确                             | 使用：\| Attempt \| What Was Tried \| Why It Failed \| Lesson Learned \|                                          |
| "Quick Reference should use ###"                 | 使用了 `## Quick Reference` 而不是 `###`   | 降级为 `### Quick Reference`（作为 Verified Workflow 的子节）                                                     |
| Skill not in marketplace                         | 文件未提交或位置错误                       | 确认位于 `skills/<name>.md`（skills 目录根部，而非嵌套）                                                          |

### 问题：PR 已存在

**原因**：分支在先前的尝试中已经被推送。

**解决方案**：删除该分支后重新推送，或更新现有 PR：

```bash
# Delete old branch and try again
git push origin :skill/<name>
git push -u origin skill/<name>

# OR update existing PR
git push origin skill/<name>
```

### 问题：清理目录

**原因**：位于 `$HOME/.agent-brain/ProjectMnemosyne` 的共享克隆会占用磁盘空间。

**解决方案**：可以随时安全删除 —— 下次 `/advise` 或 `/learn` 时会自动重新克隆：

```bash
rm -rf $HOME/.agent-brain/ProjectMnemosyne
```

## 必需部分

| Section                  | Format                                                                  | Purpose          |
| ------------------------ | ----------------------------------------------------------------------- | ---------------- |
| **YAML frontmatter**     | 以 `---` 开始，包含 name/description/category/date/version/verification | 市场元数据       |
| **Overview**             | `## Overview` 加表格（date、objective、outcome、verification）          | 快速上下文       |
| **When to Use**          | 包含触发条件的项目符号列表                                              | 可发现性         |
| **Verified Workflow**    | 有效步骤 + `### Quick Reference` 子节                                   | 实际解决方案     |
| **Failed Attempts**      | 表格：Attempt、What Was Tried、Why Failed、Lesson                       | 防止重复浪费精力 |
| **Results & Parameters** | 可直接复制粘贴的配置、预期输出                                          | 可执行参考       |

## 示例

```
/hephaestus:learn
```

Claude 将分析本次会话，检查是否存在可修订的现有技能，并且要么更新现有技能（包含历史记录），要么创建一个新技能。
