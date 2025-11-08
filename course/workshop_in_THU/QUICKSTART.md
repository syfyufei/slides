# 快速启动指南

## 🎯 一键渲染命令

### 课堂演示版（推荐，快速渲染）

```bash
quarto render Discourse_NLP_Lecture_SOTU_full.qmd
```

**特点**：
- ⚡ 快速渲染（约 30-60 秒）
- 📊 展示所有代码，但不执行
- ✅ 适合课堂演示和阅读
- 🎨 完整样式和布局

### 完整实操版（包含真实数据分析）

```bash
quarto render Discourse_NLP_Lecture_SOTU_full.qmd -P eval_code:true
```

**特点**：
- 🔬 执行所有 R 代码
- 📈 生成真实图表和分析结果
- ⏱️ 首次运行需要 5-15 分钟
- 📡 需要网络连接（下载 SOTU 数据）

**前置条件**：
1. 已安装所有 R 依赖包（见下方）
2. 网络连接正常

---

## 📦 依赖包快速安装

### R 包（必需）

```r
# 复制粘贴到 R 控制台运行
install.packages(c(
  "knitr", "rmarkdown", "quarto",
  "readr", "dplyr", "tidyr", "ggplot2",
  "quanteda", "quanteda.textstats",
  "stm", "igraph", "yaml",
  "lmtest", "sandwich", "irr",
  "jsonlite", "broom"
))
```

### Python 包（可选，用于语义距离分析）

```bash
pip install sentence-transformers pandas numpy
```

**注意**：Python 部分默认不执行，即使在 `eval_code:true` 模式下。

---

## 🗂️ 项目结构速览

```
workshop_in_THU/
├─ Discourse_NLP_Lecture_SOTU_full.qmd  ⭐ 主幻灯片
├─ Discourse_NLP_Lecture_SOTU_full.html ✅ 渲染产物
├─ README.md                             📖 完整文档
├─ QUICKSTART.md                         🚀 本文件
│
├─ data/
│  └─ sotu.csv                           📊 自动生成
│
├─ dict/
│  └─ dict_en.yml                        📚 风格字典
│
├─ scripts/
│  ├─ fetch_sotu.R                       🔽 数据获取
│  └─ make_collocation_graph.R           🕸️ 网络生成
│
├─ assets/
│  ├─ styles.css                         🎨 自定义样式
│  └─ logo.svg                           🖼️ Logo
│
└─ outputs/                              📁 输出目录
   ├─ figs/                              (图像)
   └─ tables/                            (数据表)
```

---

## 🎬 演示模式快捷键

打开 HTML 文件后，使用以下快捷键：

| 快捷键 | 功能 |
|--------|------|
| `→` / `Space` | 下一张幻灯片 |
| `←` | 上一张幻灯片 |
| `Esc` / `O` | 缩略图总览 |
| `S` | 演讲者视图（显示备注） |
| `F` | 全屏模式 |
| `B` | 黑屏/恢复 |
| `C` | 绘图模式（粉笔板） |
| `?` | 显示所有快捷键 |

---

## ⚙️ 高级参数配置

### 修改参数示例

```bash
# 修改滚动窗口大小
quarto render Discourse_NLP_Lecture_SOTU_full.qmd \
  -P eval_code:true \
  -P smooth_window:7

# 禁用 decade 标准化
quarto render Discourse_NLP_Lecture_SOTU_full.qmd \
  -P eval_code:true \
  -P standardize_by_decade:false

# 组合多个参数
quarto render Discourse_NLP_Lecture_SOTU_full.qmd \
  -P eval_code:true \
  -P smooth_window:10 \
  -P standardize_by_decade:false
```

### 可用参数列表

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `eval_code` | `false` | 是否执行代码块 |
| `data_source` | `"quanteda_rds"` | 数据源类型 |
| `smooth_window` | `5` | 滚动平均窗口大小 |
| `standardize_by_decade` | `true` | 是否按年代标准化 |
| `lang` | `"zh"` | 界面语言 |
| `show_notes` | `false` | 是否显示讲者备注 |

---

## 🐛 常见问题

### Q: 渲染时报错 "Package 'xxx' not found"

**A**: 运行依赖包安装命令（见上方）

### Q: 数据获取失败

**A**: 检查网络连接，或手动运行：

```r
source("scripts/fetch_sotu.R")
```

### Q: 渲染速度太慢

**A**:
- 使用课堂演示版（默认，不执行代码）
- 或注释掉耗时的代码块（如 STM）

### Q: 想导出为 PDF

**A**:

```bash
# 首先安装 TinyTeX
Rscript -e "tinytex::install_tinytex()"

# 然后渲染为 PDF
quarto render Discourse_NLP_Lecture_SOTU_full.qmd --to pdf
```

---

## 📧 获取帮助

- 📖 完整文档：[README.md](README.md)
- 💬 课程答疑：联系作者
- 🐞 报告问题：提交 Issue

---

## ✅ 验收清单

渲染成功后，您应该能看到：

- [x] HTML 文件已生成（约 100KB）
- [x] 幻灯片可以正常打开和浏览
- [x] 代码高亮显示正确
- [x] 样式和布局美观
- [x] 所有图片和 logo 正常显示

如果执行了 `eval_code:true`，还应该有：

- [x] `data/sotu.csv` 数据文件
- [x] `outputs/tables/` 中的分析表格
- [x] `outputs/figs/` 中的可视化图表

---

**🎉 祝演示成功！**

有任何问题随时联系：adrian.sun@example.com
