# ==============================================================================
# Generate All Analyses with FULL SOTU Dataset (240 documents, 1790-2019)
# ==============================================================================
# This script runs ALL analyses with the complete dataset and generates
# actual outputs for the presentation
# ==============================================================================

cat("=== Full Dataset Analysis Pipeline ===\n")
cat("Using 240 SOTU speeches (1790-2019)\n\n")

# ------------------------------------------------------------------------------
# 0. Setup
# ------------------------------------------------------------------------------

# Load packages
required_packages <- c(
  "readr", "dplyr", "tidyr", "ggplot2", "yaml",
  "quanteda", "quanteda.textstats", "quanteda.textplots",
  "stm", "igraph", "lmtest", "sandwich", "broom", "irr"
)

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org/")
    library(pkg, character.only = TRUE)
  }
}

# Configure Chinese font
if (Sys.info()["sysname"] == "Darwin") {
  tryCatch({
    if (!require("showtext", quietly = TRUE)) {
      install.packages("showtext")
      library(showtext)
    }
    showtext::showtext_auto()
    showtext::font_add("heiti", "/System/Library/Fonts/STHeiti Light.ttc")
    theme_set(theme_minimal(base_size = 14, base_family = "heiti"))
  }, error = function(e) {
    theme_set(theme_minimal(base_size = 14))
  })
}

# Create output directories
dir.create("outputs/figs", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# 1. Load Full Dataset
# ------------------------------------------------------------------------------

cat("Step 1: Loading full SOTU dataset...\n")
d <- read_csv("data/sotu_full.csv", show_col_types = FALSE)
cat("✓ Loaded", nrow(d), "documents\n")
cat("  Year range:", min(d$year), "-", max(d$year), "\n\n")

# ------------------------------------------------------------------------------
# 2. Text Preprocessing
# ------------------------------------------------------------------------------

cat("Step 2: Preprocessing full corpus...\n")

# Create corpus
corp <- corpus(d, text_field = "text")

# Tokenize and clean
tok <- tokens(corp, remove_punct = TRUE, remove_numbers = TRUE) %>%
  tokens_tolower() %>%
  tokens_remove(stopwords("en"))

# Create DFM
dfm_full <- dfm(tok)

cat("✓ Preprocessing complete\n")
cat("  Documents:", ndoc(dfm_full), "\n")
cat("  Features:", nfeat(dfm_full), "\n")
cat("  Sparsity:", round(sparsity(dfm_full) * 100, 2), "%\n\n")

# ------------------------------------------------------------------------------
# 3. Dictionary Method Analysis
# ------------------------------------------------------------------------------

cat("Step 3: Running dictionary method analysis...\n")

# Load dictionary
dict_list <- yaml::read_yaml("dict/dict_en.yml")
dict <- dictionary(dict_list)

# Apply dictionary
dfm_dict <- dfm_full %>% dfm_lookup(dict)
style_scores <- convert(dfm_dict, to = "data.frame")

# Merge with metadata
d_style <- d %>%
  select(year, President, party) %>%
  bind_cols(style_scores %>% select(-doc_id))

# Calculate per-thousand-word rates
total_words <- ntoken(tok)
d_style$tough_pct <- (d_style$tough / total_words) * 1000
d_style$polite_pct <- (d_style$polite / total_words) * 1000
d_style$vague_pct <- (d_style$vague / total_words) * 1000

# Save
write.csv(d_style, "outputs/tables/style_indices_full.csv", row.names = FALSE)

# Create visualization
d_long <- d_style %>%
  select(year, tough_pct, polite_pct, vague_pct) %>%
  pivot_longer(cols = -year, names_to = "style", values_to = "score") %>%
  mutate(style = gsub("_pct", "", style))

# Add 5-year rolling average
d_long <- d_long %>%
  group_by(style) %>%
  arrange(year) %>%
  mutate(score_smooth = zoo::rollmean(score, k = 5, fill = NA, align = "center")) %>%
  ungroup()

p1 <- ggplot(d_long, aes(x = year, y = score_smooth, color = style)) +
  geom_line(size = 1.5) +
  scale_color_manual(
    values = c("tough" = "#e74c3c", "polite" = "#27ae60", "vague" = "#95a5a6"),
    labels = c("强硬 (Tough)", "礼貌 (Polite)", "模糊 (Vague)")
  ) +
  labs(
    title = "SOTU 风格指数随时间变化 (1790-2019)",
    subtitle = "5年滚动平均",
    x = "年份",
    y = "风格指数（每千词）",
    color = "风格类别"
  ) +
  theme(legend.position = "bottom")

ggsave("outputs/figs/style_trends_full.png", p1, width = 12, height = 7, dpi = 150)

cat("✓ Dictionary analysis complete\n")
cat("  → outputs/figs/style_trends_full.png\n")
cat("  → outputs/tables/style_indices_full.csv\n\n")

# ------------------------------------------------------------------------------
# 4. Decade Z-score Standardization
# ------------------------------------------------------------------------------

cat("Step 4: Computing decade Z-scores...\n")

d_style_z <- d_style %>%
  mutate(decade = floor(year / 10) * 10) %>%
  group_by(decade) %>%
  mutate(
    tough_z = scale(tough_pct)[,1],
    polite_z = scale(polite_pct)[,1],
    vague_z = scale(vague_pct)[,1]
  ) %>%
  ungroup()

write.csv(d_style_z, "outputs/tables/style_zscore.csv", row.names = FALSE)

# Visualize Z-scores
d_z_long <- d_style_z %>%
  select(year, tough_z, polite_z, vague_z) %>%
  pivot_longer(cols = -year, names_to = "style", values_to = "zscore") %>%
  mutate(style = gsub("_z", "", style))

p2 <- ggplot(d_z_long, aes(x = year, y = zscore, color = style)) +
  geom_line(size = 1.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(
    values = c("tough" = "#e74c3c", "polite" = "#27ae60", "vague" = "#95a5a6"),
    labels = c("强硬 (Tough)", "礼貌 (Polite)", "模糊 (Vague)")
  ) +
  labs(
    title = "SOTU 风格指数 Z-score (按年代标准化)",
    x = "年份",
    y = "Z-score",
    color = "风格类别"
  ) +
  theme(legend.position = "bottom")

ggsave("outputs/figs/style_zscore.png", p2, width = 12, height = 7, dpi = 150)

cat("✓ Z-score standardization complete\n")
cat("  → outputs/figs/style_zscore.png\n")
cat("  → outputs/tables/style_zscore.csv\n\n")

# ------------------------------------------------------------------------------
# 5. STM Topic Model
# ------------------------------------------------------------------------------

cat("Step 5: Running STM topic model...\n")

# Prepare data for STM
dfm_stm <- dfm_full %>%
  dfm_trim(min_termfreq = 10, min_docfreq = 5)

# Convert to STM format
stm_data <- convert(dfm_stm, to = "stm")

# Prepare metadata
meta <- data.frame(
  year = d$year,
  party = d$party
)

# Fit STM (K=10 topics)
set.seed(123)
stm_fit <- stm(
  documents = stm_data$documents,
  vocab = stm_data$vocab,
  K = 10,
  prevalence = ~ s(year) + party,
  data = meta,
  init.type = "Spectral",
  verbose = FALSE,
  max.em.its = 75
)

# Save top words for each topic
topic_words <- labelTopics(stm_fit, n = 10)
topic_df <- data.frame(
  topic = 1:10,
  top_words = apply(topic_words$prob, 1, function(x) paste(x, collapse = ", "))
)
write.csv(topic_df, "outputs/tables/stm_topics.csv", row.names = FALSE)

# Visualize topic prevalence over time
effects <- estimateEffect(1:10 ~ s(year) + party, stm_fit, meta = meta)

# Plot top 5 topics
png("outputs/figs/stm_topics_time.png", width = 1400, height = 1000, res = 150)
par(mfrow = c(2, 3), family = "sans")
for (i in 1:5) {
  plot(effects, "year", method = "continuous", topics = i,
       main = paste("主题", i, ":", paste(topic_words$prob[i, 1:3], collapse = ", ")),
       xlab = "年份", ylab = "预期主题比例")
}
dev.off()

cat("✓ STM analysis complete\n")
cat("  → outputs/figs/stm_topics_time.png\n")
cat("  → outputs/tables/stm_topics.csv\n\n")

# ------------------------------------------------------------------------------
# 6. Collocation Network
# ------------------------------------------------------------------------------

cat("Step 6: Generating collocation networks...\n")

# Calculate bigram collocations
colls <- textstat_collocations(tok, size = 2, min_count = 20)
top_colls <- head(colls, 50)

# Create network
library(igraph)

edges <- data.frame(
  from = sapply(strsplit(top_colls$collocation, " "), `[`, 1),
  to = sapply(strsplit(top_colls$collocation, " "), `[`, 2),
  weight = top_colls$count
)

g <- graph_from_data_frame(edges, directed = FALSE)

# Plot network
png("outputs/figs/collocation_network.png", width = 1200, height = 1200, res = 150)
set.seed(123)
plot(g,
     vertex.size = degree(g) * 2,
     vertex.label.cex = 0.8,
     vertex.color = "lightblue",
     edge.width = E(g)$weight / 10,
     layout = layout_with_fr(g),
     main = "SOTU 词汇共现网络 (Top 50 Bigrams)")
dev.off()

write.csv(top_colls, "outputs/tables/collocations.csv", row.names = FALSE)

cat("✓ Collocation network complete\n")
cat("  → outputs/figs/collocation_network.png\n")
cat("  → outputs/tables/collocations.csv\n\n")

# ------------------------------------------------------------------------------
# 7. Regression Analysis
# ------------------------------------------------------------------------------

cat("Step 7: Running regression analysis...\n")

# Create war period indicator
d_style$war_period <- ifelse(
  d_style$year %in% c(1812:1815, 1846:1848, 1861:1865, 1898,
                       1917:1918, 1941:1945, 1950:1953, 1965:1973,
                       1990:1991, 2001:2011),
  1, 0
)

d_style$republican <- ifelse(d_style$party == "Republican", 1, 0)

# OLS regression
model_ols <- lm(tough_pct ~ war_period + republican, data = d_style)

# Robust standard errors
model_robust <- coeftest(model_ols, vcov = vcovHC(model_ols, type = "HC1"))

# Save output
capture.output({
  print(summary(model_ols))
  cat("\n=== Robust Standard Errors ===\n")
  print(model_robust)
}, file = "outputs/tables/regression_output.txt")

# Visualize coefficients
coef_df <- tidy(model_robust, conf.int = TRUE) %>%
  filter(term != "(Intercept)")

p3 <- ggplot(coef_df, aes(x = estimate, y = term)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
  labs(
    title = "回归系数图：强硬指数的预测因子",
    subtitle = "95% 置信区间（稳健标准误）",
    x = "系数估计值",
    y = ""
  ) +
  theme_minimal(base_size = 14)

ggsave("outputs/figs/regression_coef_full.png", p3, width = 8, height = 6, dpi = 150)

cat("✓ Regression analysis complete\n")
cat("  → outputs/figs/regression_coef_full.png\n")
cat("  → outputs/tables/regression_output.txt\n\n")

# ------------------------------------------------------------------------------
# 8. Word Frequency
# ------------------------------------------------------------------------------

cat("Step 8: Generating word frequency analysis...\n")

word_freq <- textstat_frequency(dfm_full)
write.csv(head(word_freq, 100), "outputs/tables/word_frequency_full.csv", row.names = FALSE)

p4 <- word_freq %>%
  head(20) %>%
  ggplot(aes(x = reorder(feature, frequency), y = frequency)) +
  geom_col(fill = "#1f77b4") +
  coord_flip() +
  labs(
    title = "SOTU Top 20 高频词 (1790-2019)",
    x = NULL,
    y = "出现次数"
  ) +
  theme_minimal(base_size = 14)

ggsave("outputs/figs/word_frequency_full.png", p4, width = 8, height = 6, dpi = 150)

# Word cloud
png("outputs/figs/wordcloud_full.png", width = 1000, height = 800, res = 150)
textplot_wordcloud(dfm_full, min_count = 100, max_words = 100,
                   color = c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd"))
dev.off()

cat("✓ Word frequency analysis complete\n")
cat("  → outputs/figs/word_frequency_full.png\n")
cat("  → outputs/figs/wordcloud_full.png\n")
cat("  → outputs/tables/word_frequency_full.csv\n\n")

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

cat("\n=== Analysis Pipeline Complete! ===\n\n")
cat("Generated outputs with FULL dataset (240 documents, 1790-2019):\n\n")
cat("Figures:\n")
cat("  - style_trends_full.png (完整时期风格趋势)\n")
cat("  - style_zscore.png (Z-score标准化)\n")
cat("  - stm_topics_time.png (STM主题随时间变化)\n")
cat("  - collocation_network.png (词汇共现网络)\n")
cat("  - regression_coef_full.png (回归系数图)\n")
cat("  - word_frequency_full.png (词频柱状图)\n")
cat("  - wordcloud_full.png (词云)\n\n")
cat("Tables:\n")
cat("  - style_indices_full.csv (完整风格指数)\n")
cat("  - style_zscore.csv (Z-score数据)\n")
cat("  - stm_topics.csv (STM主题词)\n")
cat("  - collocations.csv (搭配词数据)\n")
cat("  - regression_output.txt (回归结果)\n")
cat("  - word_frequency_full.csv (词频数据)\n\n")
cat("All analyses use the complete SOTU corpus!\n")
