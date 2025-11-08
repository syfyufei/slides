# Discourse NLP Lecture: SOTU Full Demo

## 项目简介

这是《话语分析方法及应用》课程的完整演示项目，基于美国总统国情咨文（State of the Union, SOTU）真实数据，展示如何将文本数据转化为可量化的社会科学证据。

**核心理念**："见字为数"——把文本变成能进工具箱的变量，用数据描述、网络分析、回归/因果等方法读懂它。

## 项目结构

```
.
├─ Discourse_NLP_Lecture_SOTU_full.qmd   # 主幻灯片（Quarto Reveal.js）
├─ data/
│  └─ sotu.csv                           # SOTU 数据（自动生成）
├─ dict/
│  └─ dict_en.yml                        # 风格字典（tough/polite/vague）
├─ scripts/
│  ├─ fetch_sotu.R                       # 数据获取脚本
│  └─ make_collocation_graph.R           # 搭配网络生成脚本
├─ assets/
│  ├─ styles.css                         # 自定义样式
│  └─ logo.svg                           # Logo（占位）
├─ outputs/
│  ├─ figs/                              # 图像输出目录
│  └─ tables/                            # 表格输出目录
└─ README.md                             # 本文件
```

## 快速开始

### 1. 环境准备

#### 安装 R 包

```r
# 核心依赖
install.packages(c(
  "quarto",          # Quarto 渲染引擎
  "knitr",           # R Markdown 核心
  "rmarkdown",       # Markdown 渲染
  "readr",           # 数据读写
  "dplyr",           # 数据处理
  "tidyr",           # 数据整理
  "ggplot2",         # 可视化
  "yaml",            # YAML 解析
  "quanteda",        # 文本分析
  "quanteda.textstats",  # 文本统计
  "stm",             # 结构化主题模型
  "igraph",          # 网络分析
  "lmtest",          # 回归检验
  "sandwich",        # 稳健标准误
  "irr",             # 一致性检验
  "jsonlite",        # JSON 处理
  "broom"            # 模型整理
))
```

#### 安装 Python 包（可选，用于语义距离分析）

```bash
pip install sentence-transformers pandas numpy
```

### 2. 获取数据

#### 方法 A：自动获取（推荐）

```r
# 在 R 中运行
source("scripts/fetch_sotu.R")
```

这会从 quanteda 官方数据源下载 SOTU 语料并保存到 `data/sotu.csv`。

#### 方法 B：手动准备

如果网络受限，可以：

1. 从其他渠道获取 SOTU 数据
2. 保存为 `data/sotu.csv`，包含以下字段：
   - `date`: 日期（格式：YYYY-MM-DD）
   - `president`: 总统姓名
   - `party`: 党派（Democratic/Republican）
   - `text`: 演讲全文
   - `year`: 年份（可选，会自动生成）

### 3. 渲染幻灯片

#### 课堂演示版（不执行代码，快速渲染）

```bash
quarto render Discourse_NLP_Lecture_SOTU_full.qmd
```

这会生成 HTML 幻灯片，所有代码块仅展示但不执行，适合课堂演示。

#### 完整实操版（执行所有代码）

```bash
quarto render Discourse_NLP_Lecture_SOTU_full.qmd -P eval_code:true
```

这会执行所有 R/Python 代码块，生成真实的分析结果和图表。**首次运行需要较长时间**（约 5-15 分钟，取决于网络和计算资源）。

### 4. 查看结果

渲染完成后，在项目目录下会生成：

- `Discourse_NLP_Lecture_SOTU_full.html` - 主幻灯片
- `outputs/figs/` - 所有图表
- `outputs/tables/` - 所有数据表

用浏览器打开 HTML 文件即可查看和演示。

## 参数配置

主幻灯片支持以下参数（在 YAML 头部定义）：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `eval_code` | `false` | 是否执行代码块 |
| `data_source` | `"quanteda_rds"` | 数据源（`"quanteda_rds"` 或 `"csv"`） |
| `smooth_window` | `5` | 时间序列滚动窗口大小 |
| `standardize_by_decade` | `true` | 是否按年代标准化风格指数 |
| `lang` | `"zh"` | 界面语言（预留） |
| `show_notes` | `false` | 是否显示讲者备注 |

### 修改参数

#### 方法 1：命令行参数

```bash
quarto render Discourse_NLP_Lecture_SOTU_full.qmd \
  -P eval_code:true \
  -P smooth_window:7 \
  -P standardize_by_decade:false
```

#### 方法 2：修改 YAML

直接编辑 `.qmd` 文件的 `params` 部分：

```yaml
params:
  eval_code: true
  smooth_window: 7
  standardize_by_decade: false
```

## 核心功能

### 1. 字典法（Dictionary Method）

- 定义风格词典（tough/polite/vague）
- 计算每篇文档的风格指数
- 可视化随时间变化的趋势
- 支持按年代标准化（z-score）

**相关文件**：
- `dict/dict_en.yml` - 字典定义
- 幻灯片第 "路线 1：字典法" 章节

### 2. 主题模型（Structural Topic Model, STM）

- 发现潜在主题（K=10）
- 加入年份和党派作为协变量
- 可视化主题随时间的演变

**相关文件**：
- 幻灯片第 "路线 2：主题模型" 章节

### 3. 搭配网络（Collocation Network）

- 计算显著 bigram/trigram
- 构建词共现网络
- 对比不同年代的网络结构（1940s vs 1990s）
- 计算网络指标：密度、聚类系数、社群结构

**相关文件**：
- `scripts/make_collocation_graph.R` - 网络生成脚本
- `outputs/figs/network_*.png` - 网络可视化
- `outputs/tables/collocations_*.csv` - 搭配数据
- `outputs/tables/network_metrics_*.csv` - 网络指标

### 4. 语义距离（Semantic Distance）

- 使用句子嵌入（Sentence Transformers）
- 定义"战争锚点"和"和平锚点"
- 计算每年与锚点的余弦距离
- 可视化语义漂移

**相关文件**：
- 幻灯片第 "路线 4：语义距离" 章节
- `outputs/tables/semantic_distance.csv` - 语义距离数据

**依赖**：需要安装 Python 包 `sentence-transformers`

### 5. LLM 标注（LLM Annotation）

- 提供 Few-shot 提示词模板
- 演示批量标注流程
- 计算人工标注与 LLM 标注的一致性（Cohen's Kappa）

**相关文件**：
- 幻灯片第 "路线 5：LLM 标注" 章节
- `outputs/tables/sample_labels.jsonl` - 示例标注数据

**注意**：幻灯片中不调用真实 API，仅提供模拟示例。

### 6. 回归分析（Regression Analysis）

- 研究问题：战争时期是否更"强硬"？
- 回归模型：控制党派、总统固定效应、年份趋势
- 稳健标准误（HC1）
- 系数可视化
- 敏感性分析

**相关文件**：
- 幻灯片第 "迷你结论：实证演示" 章节

## 常见问题（FAQ）

### Q1: 渲染时报错 "Package 'xxx' not found"

**A**: 请确保安装了所有依赖包（见"环境准备"）。可以运行：

```r
source("scripts/check_dependencies.R")  # 如果提供
```

或手动安装缺失的包。

### Q2: 数据获取失败怎么办？

**A**: 有三种解决方案：

1. 检查网络连接，重试 `source("scripts/fetch_sotu.R")`
2. 使用备用数据源（见脚本内的备选方法）
3. 手动下载 CSV 文件并放到 `data/sotu.csv`

### Q3: 渲染速度很慢

**A**:

- **课堂演示**：使用默认参数（`eval_code: false`），只展示代码不执行，速度很快
- **完整运行**：首次执行需要时间，后续可以利用缓存加速
- **部分执行**：可以注释掉不需要的代码块（如 STM 部分）

### Q4: 如何导出为 PDF？

**A**:

```bash
quarto render Discourse_NLP_Lecture_SOTU_full.qmd --to pdf
```

注意：PDF 导出需要安装 LaTeX（推荐 TinyTeX）：

```r
install.packages("tinytex")
tinytex::install_tinytex()
```

### Q5: 如何在自己的数据上使用？

**A**:

1. 准备数据 CSV，包含 `text` 字段和其他元数据
2. 修改脚本中的数据读取路径
3. 根据需要调整字典、主题数量等参数
4. 重新渲染

### Q6: 讲者备注如何显示？

**A**:

- 在 Reveal.js 演示模式下按 `S` 键打开演讲者视图
- 或修改参数：`show_notes: true`（但会在主幻灯片上显示，不推荐）

## 技术说明

### 技术栈

- **渲染引擎**: Quarto (Pandoc-based)
- **演示格式**: Reveal.js
- **R 分析**: quanteda, stm, ggplot2
- **Python 分析**: sentence-transformers（可选）
- **样式**: 自定义 CSS

### 浏览器兼容性

推荐使用现代浏览器：

- Chrome/Edge (最佳)
- Firefox
- Safari

### 已知限制

1. **Python 代码块**：需要 `reticulate` 包和 Python 环境，默认不执行
2. **网络依赖**：首次获取数据需要网络连接
3. **计算资源**：完整运行 STM 需要较多内存（建议 ≥8GB RAM）

## 引用与致谢

### 数据来源

- **quanteda Project**: https://quanteda.org
- **SOTU Corpus**: quanteda.corpora 包

### 主要参考文献

- Grimmer, J., Roberts, M. E., & Stewart, B. M. (2022). *Text as Data: A New Framework for Machine Learning and the Social Sciences*. Princeton University Press.
- Roberts, M. E., Stewart, B. M., & Tingley, D. (2019). "stm: An R Package for Structural Topic Models." *Journal of Statistical Software*, 91(2), 1-40.
- Benoit, K., Watanabe, K., Wang, H., et al. (2018). "quanteda: An R package for the quantitative analysis of textual data." *Journal of Open Source Software*, 3(30), 774.

### 许可证

本项目采用 **CC-BY 4.0** 许可证。您可以自由使用、修改和分享，但需注明出处。

## 联系方式

- **作者**: 孙宇飞（Adrian Sun）
- **Email**: adrian.sun@example.com
- **GitHub**: https://github.com/adriansun

## 更新日志

### v1.0.0 (2025-10-13)

- 初始版本
- 完整五条路线实现
- 支持参数化渲染
- 完善文档和示例

---

**祝教学/研究顺利！**

如有问题或建议，欢迎提 Issue 或 Pull Request。
