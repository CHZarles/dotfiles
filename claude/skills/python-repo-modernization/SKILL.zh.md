# Python 仓库现代化

## 概览

| 属性     | 值                                                                                                                            |
| -------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **日期** | 2026-03-13                                                                                                                    |
| **目标** | 将一个部分现代化的 Python 仓库提升到生产级质量：修复 bug、重构测试、增强 CI/pre-commit、添加 PEP 561 标记、为 PyPI 发布做准备 |
| **结果** | ✅ 184 个测试通过，61% 覆盖率，所有导入已验证，发布工作流已创建                                                               |
| **项目** | ProjectHephaestus v0.3.0 (Hatchling + Pixi + ruff/mypy)                                                                       |

## 何时使用

当你需要执行以下操作时，请使用此技能：

- 修复 Python 包中的循环导入
- 移除不再需要的向后兼容垫片
- 将扁平的 `tests/` 重构为与源码布局镜像对应的 `tests/unit/<subpackage>/`
- 为下游类型使用者添加 PEP 561 `py.typed` 标记
- 加强 pre-commit hooks（CVE 扫描、锁文件新鲜度、结构强制、复杂度）
- 使用矩阵策略和 codecov 标志增强 GitHub Actions CI
- 创建由语义化版本标签触发的 PyPI 发布工作流
- 修复引用已重命名函数或已删除模块的过时文档

**触发语：**

- “把这个仓库提升到生产级”
- “达到 [other repo] 的质量标准”
- “为 PyPI 发布做准备”
- “重构测试以镜像包布局”
- “修复 `__init__.py` 中的循环导入”

## 已验证的工作流

### 1. 修复循环导入

当子模块从包自身的 `__init__.py` 导入时，直接使用 `importlib.metadata`：

```python
# ❌ 循环导入：hephaestus/cli/utils.py
from hephaestus import __version__

# ✅ 直接使用 importlib.metadata
from importlib.metadata import PackageNotFoundError, version as _pkg_version
try:
    __version__ = _pkg_version("hephaestus")
except PackageNotFoundError:
    __version__ = "0.3.0"
```

### 2. 修复可选列表参数的类型提示

```python
# ❌ 错误 —— 默认值 None 不是合法的 list[float]
retry_delays: list[float] = None

# ✅ 正确
retry_delays: list[float] | None = None
```

### 3. 修复类型强制转换中的布尔逻辑

当从字符串环境变量中检测浮点数时，条件必须检查 `.` 是否存在，而不是不存在：

```python
# ❌ 原始实现 —— 逻辑反了，在没有点号时尝试 float
if '.' not in value and value.isdigit():
    value = int(value)
elif '.' not in value:           # ← 这也会匹配非浮点字符串
    value = float(value)

# ✅ 修复后 —— 使用单独的已类型化变量，不要重新赋值给 value
typed_value: int | float | str = value
try:
    if '.' not in value and value.isdigit():
        typed_value = int(value)
    elif '.' in value:
        typed_value = float(value)
except ValueError:
    pass
current[keys[-1]] = typed_value  # 存储已类型化的值，而不是 str
```

### 4. 添加 PEP 561 标记

```bash
touch hephaestus/py.typed
```

这个空文件会向 mypy 和其他类型检查器表明该包随附内联类型。

### 5. 删除向后兼容垫片

当一个垫片模块只是从规范位置重新导出内容，且没有任何地方导入它时：

```bash
rm -rf hephaestus/helpers/
```

验证没有残留引用：

```bash
grep -r "hephaestus.helpers" .  # 应该没有任何输出
```

### 6. 重构测试以镜像包布局

```
tests/
  __init__.py
  unit/
    __init__.py
    cli/
      __init__.py
      test_colors.py
      test_utils.py
    config/
      __init__.py
      test_utils.py
    utils/
      __init__.py
      test_general_utils.py
    ...  （每个 hephaestus/ 子包对应一个子目录）
```

使用 `cp` 移动文件，然后删除原文件。为每个新目录添加 `__init__.py`。更新 `pyproject.toml`：

```toml
[tool.pytest.ini_options]
testpaths = ["tests/unit"]
pythonpath = [".", "scripts"]
```

### 7. 添加结构强制检查脚本

创建 `scripts/check_unit_test_structure.py`，用于验证每个 `hephaestus/<subpackage>` 都有对应的 `tests/unit/<subpackage>/` 目录。将其接入为 pre-commit hook：

```yaml
- id: check-unit-test-structure
  name: Check unit test structure
  entry: python scripts/check_unit_test_structure.py
  language: system
  pass_filenames: false
  files: ^(hephaestus|tests/unit)/
```

### 8. 加强 Pre-commit Hooks

向 `.pre-commit-config.yaml` 添加：

```yaml
# CVE 扫描（手动阶段，避免阻塞每次提交）
- id: pip-audit
  name: pip-audit (CVE scan)
  entry: pixi run pip-audit
  language: system
  pass_filenames: false
  stages: [manual]

# 锁文件新鲜度检查
- id: check-pixi-lock
  name: Check pixi lock file
  entry: pixi install --locked
  language: system
  pass_filenames: false
  files: ^pixi\.(toml|lock)$

# 复杂度强制检查
- id: ruff-check-complexity
  name: Ruff Complexity Check (C901)
  entry: pixi run ruff check --select C901 hephaestus/
  language: system
  files: ^hephaestus/.*\.py$
  types: [python]
  pass_filenames: false
```

### 9. 增强 test.yml CI

添加矩阵策略（以后可扩展到集成测试）和 codecov 标志：

```yaml
strategy:
  matrix:
    test-type: [unit]

# 使用硬编码路径以避免矩阵注入风险
- name: Run unit tests
  run: |
    pixi run pytest tests/unit ...

- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    flags: unit
```

**安全说明：** 不要在 `run:` 命令中使用 `${{ matrix.test-type }}` —— 请硬编码测试路径。同一工作流文件中的矩阵值在 `name:` 字段中是安全的，但如果在 `run:` 中使用，一旦矩阵将来接受外部输入，就会带来命令注入风险。

### 10. 添加 PyPI 发布工作流

在语义化版本标签上触发，使用 Trusted Publishing（OIDC）模式：

```yaml
on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  id-token: write

- name: Build package
  run: pixi run python -m build

- name: Publish to PyPI
  uses: pypa/gh-action-pypi-publish@release/v1
  with:
    password: ${{ secrets.PYPI_API_TOKEN }}
```

### 11. 修复 README/CLAUDE.md 中的过时引用

需要查找并修复的常见过时模式：

| 过时项                                      | 正确项                         |
| ------------------------------------------- | ------------------------------ |
| `hephaestus.utils.general`                  | `hephaestus.utils`             |
| `run_command`                               | `run_subprocess`               |
| `get_nested_value`                          | `get_setting`                  |
| `pixi run docs-build`                       | （删除 —— 该任务不存在）       |
| `Python 3.8+`                               | `Python 3.10+`                 |
| `requirements.txt` / `requirements-dev.txt` | `pixi.toml` / `pyproject.toml` |
| `flake8` / `black` / `tox`                  | `ruff` / `pixi run`            |

## 失败的尝试

### ❌ 浮点强制转换 —— 将 `value` 重新赋值为 `str(converted)`

**发生了什么：** 对浮点逻辑的初始修复把转换后的值又作为字符串存回去了（`value = str(converted)`），这保留了 bug 的最终效果（所有内容仍然被存为字符串）。

**为什么失败：** `value` 是来自 `os.environ.items()` 的 `str`。将它重新赋值为 `str(converted)` 意味着嵌套配置键最终仍然得到一个字符串，而不是 int/float。

**修复方法：** 引入单独的 `typed_value: int | float | str` 变量，并将其赋给配置字典——永远不要修改 `value`。

### ❌ 在 `run:` 命令中使用 `${{ matrix.test-type }}`

**发生了什么：** 最初在 `run:` 步骤中用矩阵变量对测试路径进行了模板化。

**为什么避免这样做：** GitHub Actions 安全扫描器会将 `run:` 中的矩阵值标记为潜在注入向量（即使它们是受控的）。在运行步骤中硬编码 `tests/unit` 更简洁，也能避免 pre-bash-exec hook 的安全警告。

### ❌ 仅删除 Python 文件后使用 `rmdir`

**发生了什么：** `rmdir hephaestus/helpers` 失败了，因为还残留了 `__pycache__`。

**修复方法：** 对包含 Python 文件的目录始终使用 `rm -rf`，因为在任何导入之后总会存在 `__pycache__`。

## 结果与参数

### 最终状态

```
184 tests passed in 2.99s
Coverage: 61.04% (≥50% threshold met)
hephaestus.__version__ = "0.3.0"
from hephaestus import slugify, retry_with_backoff  # ✅
python scripts/check_unit_test_structure.py         # ✅ 13/13 subpackages
```

### 关键 pyproject.toml 设置

```toml
[tool.pytest.ini_options]
testpaths = ["tests/unit"]
pythonpath = [".", "scripts"]
addopts = ["-v", "--strict-markers", "--cov=hephaestus",
           "--cov-report=term-missing", "--cov-report=html",
           "--cov-fail-under=50"]

[tool.hatch.build.targets.wheel]
packages = ["hephaestus"]  # 自动包含 py.typed
```

### Pre-commit Hook 摘要

| Hook ID                     | 用途              | 阶段   |
| --------------------------- | ----------------- | ------ |
| `check-shell-injection`     | 防止 `shell=True` | commit |
| `ruff-format-python`        | 自动格式化        | commit |
| `ruff-check-python`         | Lint + 修复       | commit |
| `mypy-check-python`         | 类型检查          | commit |
| `pip-audit`                 | CVE 扫描          | manual |
| `check-pixi-lock`           | 锁文件新鲜度检查  | commit |
| `check-unit-test-structure` | 测试布局镜像检查  | commit |
| `ruff-check-complexity`     | C901 复杂度检查   | commit |
| `markdownlint-cli2`         | Markdown lint     | commit |
| `yamllint`                  | YAML lint         | commit |

## 未来使用检查清单

- [ ] 搜索循环导入：`grep -r "from hephaestus import" hephaestus/`
- [ ] 修复 `param: list[X] = None` → `param: list[X] | None = None`
- [ ] 审查类型强制转换逻辑中的布尔偏差错误
- [ ] 删除那些仅从规范位置重新导出的垫片模块
- [ ] `touch <package>/py.typed`
- [ ] 创建带有 `__init__.py` 文件的 `tests/unit/<subpackage>/` 结构
- [ ] 更新 `pyproject.toml` 中的 testpaths 和 pythonpath
- [ ] 编写 `scripts/check_unit_test_structure.py`
- [ ] 添加 pip-audit、check-pixi-lock、结构检查、复杂度 hooks
- [ ] 创建用于标签触发 PyPI 发布的 `.github/workflows/release.yml`
- [ ] 修复 README/文档中的过时引用（函数名、模块路径、已删除任务）
- [ ] 验证：`pytest tests/unit -v` → 全部通过，覆盖率 ≥ 阈值
- [ ] 验证：`python -c "import <package>; print(<package>.__version__)"`

## 相关技能

- `github-actions-python-cicd` — 完整的 CI/CD 流水线设置
- `create-reusable-utilities` — 在项目间迁移工具函数
- `python-packaging` — Hatchling/pyproject.toml 配置
