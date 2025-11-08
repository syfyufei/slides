# ==============================================================================
# Generate All Outputs for Discourse NLP Lecture
# ==============================================================================
# This script runs all analyses and generates all figures for the slides
# Run with: Rscript scripts/generate_all_outputs.R
# ==============================================================================

cat("=== Starting Full Analysis Pipeline ===\n\n")

# ------------------------------------------------------------------------------
# 0. Setup and Package Installation
# ------------------------------------------------------------------------------

cat("Step 0: Checking and installing packages...\n")

required_packages <- c(
  "readr", "dplyr", "tidyr", "ggplot2", "yaml",
  "quanteda", "quanteda.textstats", "quanteda.textplots",
  "stm", "igraph", "lmtest", "sandwich", "broom", "irr", "jsonlite"
)

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org/")
    library(pkg, character.only = TRUE)
  }
}

cat("✓ All packages loaded\n\n")

# Configure Chinese font support for plots (macOS)
if (Sys.info()["sysname"] == "Darwin") {
  # Try to set up Chinese font for macOS
  tryCatch({
    if (!require("showtext", quietly = TRUE)) {
      install.packages("showtext", repos = "https://cloud.r-project.org/")
      library(showtext)
    }
    showtext::showtext_auto()
    showtext::font_add("heiti", regular = "/System/Library/Fonts/STHeiti Light.ttc")
    theme_set(theme_minimal(base_size = 14, base_family = "heiti"))
    cat("✓ Chinese font configured (showtext)\n\n")
  }, error = function(e) {
    # Fallback: use cairo device
    options(device = function(...) {
      grDevices::png(..., type = "quartz")
    })
    theme_set(theme_minimal(base_size = 14))
    cat("✓ Using default font (quartz device)\n\n")
  })
} else {
  theme_set(theme_minimal(base_size = 14))
  cat("✓ Using default font\n\n")
}

# ------------------------------------------------------------------------------
# 1. Fetch SOTU Data
# ------------------------------------------------------------------------------

cat("Step 1: Fetching SOTU data...\n")

# Create directories
dir.create("data", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/figs", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

# Fetch data using quanteda's built-in corpus
library(quanteda)

# Try to load quanteda's SOTU data
tryCatch({
  # First try to load from built-in quanteda data
  cat("Attempting to load full SOTU corpus...\n")

  # Try method 1: Load from URL
  sotu_url <- "https://quanteda.org/data/data_corpus_sotu.rds"
  sotu <- tryCatch({
    readRDS(url(sotu_url, "rb"))
  }, error = function(e) NULL)

  # Try method 2: Load from quanteda.corpora package
  if (is.null(sotu) && require("quanteda.corpora", quietly = TRUE)) {
    data(data_corpus_sotu, package = "quanteda.corpora")
    sotu <- data_corpus_sotu
  }

  # Fallback: Create sample dataset
  if (is.null(sotu)) {
    cat("⚠ Unable to load full corpus. Creating sample SOTU data for demonstration...\n")

    # Sample data (first few SOTUs)
    sample_texts <- c(
      "Fellow-Citizens of the Senate and House of Representatives: I embrace with great satisfaction the opportunity which now presents itself of congratulating you on the present favorable prospects of our public affairs.",
      "Fellow-Citizens of the Senate and House of Representatives: In meeting you again I feel much satisfaction in being able to repeat my congratulations on the favorable prospects which continue to distinguish our public affairs.",
      "Fellow-Citizens of the Senate and House of Representatives: In a free and republican government the public prosperity must be a subject of constant solicitude.",
      "Fellow-Citizens: The present situation of our public affairs affords much matter of consolation and just cause for mutual congratulation.",
      "Fellow-Citizens of the Senate and House of Representatives: Called by the voice of our country to their highest trust at a time when the nation's prosperity had reached an unprecedented point."
    )

    d <- data.frame(
      date = as.Date(c("1790-01-08", "1791-10-25", "1792-11-06", "1793-12-03", "1794-11-19")),
      president = c("Washington", "Washington", "Washington", "Washington", "Washington"),
      party = c("none", "none", "none", "none", "none"),
      text = sample_texts,
      year = c(1790, 1791, 1792, 1793, 1794),
      stringsAsFactors = FALSE
    )
  }

  # If we got actual SOTU data, convert it
  if (exists("sotu") && !is.null(sotu)) {
    # Check available docvars
    avail_vars <- names(docvars(sotu))
    cat("Available variables:", paste(avail_vars, collapse = ", "), "\n")
    cat("Number of documents:", ndoc(sotu), "\n")

    # Create data frame with each variable separately
    d <- data.frame(text = as.character(sotu), stringsAsFactors = FALSE)

    # Add date
    if ("Date" %in% avail_vars) {
      d$date <- docvars(sotu, "Date")
      d$year <- as.integer(format(as.Date(d$date), "%Y"))
    }

    # Add president
    if ("President" %in% avail_vars) {
      d$president <- as.character(docvars(sotu, "President"))
    } else if ("FirstName" %in% avail_vars) {
      d$president <- as.character(docvars(sotu, "FirstName"))
    } else {
      d$president <- rep("Unknown", nrow(d))
    }

    # Add party
    if ("party" %in% avail_vars) {
      d$party <- as.character(docvars(sotu, "party"))
    } else if ("Party" %in% avail_vars) {
      d$party <- as.character(docvars(sotu, "Party"))
    } else {
      d$party <- rep("Unknown", nrow(d))
    }

    cat("✓ Successfully loaded", nrow(d), "SOTU speeches\n")
  }

  # Save data
  write.csv(d, "data/sotu.csv", row.names = FALSE)
  cat("✓ Data saved to data/sotu.csv\n")
  cat("  → ", nrow(d), " documents\n\n")

}, error = function(e) {
  cat("✗ Error fetching data:", e$message, "\n")
  stop("Cannot proceed without data")
})

# ------------------------------------------------------------------------------
# 2. Text Preprocessing Demo Outputs
# ------------------------------------------------------------------------------

cat("Step 2: Generating preprocessing demo outputs...\n")

# Sample preprocessing
corp_sample <- corpus(d$text[1])
tok_sample <- tokens(corp_sample)

# Save tokenization output
capture.output({
  print(head(tok_sample, 1))
}, file = "outputs/tables/tokenization_output.txt")

# Cleaned tokens
tok_clean <- tokens(corp_sample, remove_punct = TRUE, remove_numbers = TRUE) %>%
  tokens_tolower() %>%
  tokens_remove(stopwords("en"))

capture.output({
  print(as.character(tok_clean))
}, file = "outputs/tables/cleaning_output.txt")

cat("✓ Preprocessing demo outputs saved\n\n")

# ------------------------------------------------------------------------------
# 3. Dictionary Method: Style Indices
# ------------------------------------------------------------------------------

cat("Step 3: Running dictionary method analysis...\n")

# Load dictionary
dict_list <- yaml::read_yaml("dict/dict_en.yml")
dict <- dictionary(dict_list)

# Create full corpus
corp_full <- corpus(d, text_field = "text")
tok_full <- tokens(corp_full, remove_punct = TRUE, remove_numbers = TRUE) %>%
  tokens_tolower() %>%
  tokens_remove(stopwords("en"))

# Apply dictionary
dfm_dict <- dfm(tok_full) %>% dfm_lookup(dict)

# Get style scores
style_scores <- convert(dfm_dict, to = "data.frame")

# Calculate per-thousand-word rates
d_style <- cbind(
  d[, c("year", "president", "party")],
  style_scores[, -1]
)

# Get total words
total_words <- ntoken(tok_full)
d_style$tough_pct <- (d_style$tough / total_words) * 1000
d_style$polite_pct <- (d_style$polite / total_words) * 1000
d_style$vague_pct <- (d_style$vague / total_words) * 1000

# Save style data
write.csv(d_style, "outputs/tables/style_indices.csv", row.names = FALSE)

# Create style trend plot
library(tidyr)

d_long <- d_style %>%
  select(year, tough_pct, polite_pct, vague_pct) %>%
  pivot_longer(cols = -year, names_to = "style", values_to = "score") %>%
  mutate(style = gsub("_pct", "", style))

# Add rolling average if enough data
if (nrow(d) >= 5) {
  d_long <- d_long %>%
    group_by(style) %>%
    arrange(year) %>%
    mutate(score_smooth = zoo::rollmean(score, k = min(5, nrow(d)), fill = NA, align = "center")) %>%
    ungroup()
} else {
  d_long$score_smooth <- d_long$score
}

# Plot
p1 <- ggplot(d_long, aes(x = year, y = score, color = style)) +
  geom_line(alpha = 0.3, size = 0.5) +
  geom_line(aes(y = score_smooth), size = 1.2) +
  scale_color_manual(
    values = c("tough" = "#e74c3c", "polite" = "#27ae60", "vague" = "#95a5a6"),
    labels = c("强硬 (Tough)", "礼貌 (Polite)", "模糊 (Vague)")
  ) +
  labs(
    title = "SOTU 风格指数随时间变化",
    subtitle = "滚动平均窗口：5 年",
    x = "年份",
    y = "风格指数（每千词）",
    color = "风格类别"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")

ggsave("outputs/figs/style_trends.png", p1, width = 10, height = 6, dpi = 150)

cat("✓ Dictionary analysis complete\n")
cat("  → outputs/figs/style_trends.png\n")
cat("  → outputs/tables/style_indices.csv\n\n")

# ------------------------------------------------------------------------------
# 4. Regression Analysis
# ------------------------------------------------------------------------------

cat("Step 4: Running regression analysis...\n")

# Create war period indicator (sample wars)
d_style$war_period <- ifelse(
  d_style$year %in% c(1941:1945, 1950:1953, 1965:1973, 2001:2011),
  1, 0
)

d_style$republican <- ifelse(d_style$party == "Republican", 1, 0)

# Only run if we have enough data
if (nrow(d_style) >= 10) {
  # OLS regression
  model_ols <- lm(
    tough_pct ~ war_period + republican,
    data = d_style
  )

  # Save regression output
  capture.output({
    summary(model_ols)
  }, file = "outputs/tables/regression_output.txt")

  # Coefficient plot
  library(broom)
  coef_df <- tidy(model_ols, conf.int = TRUE) %>%
    filter(term != "(Intercept)")

  if (nrow(coef_df) > 0) {
    p2 <- ggplot(coef_df, aes(x = estimate, y = term)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
      geom_point(size = 3) +
      geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
      labs(
        title = "回归系数图（强硬指数）",
        subtitle = "95% 置信区间",
        x = "系数估计值",
        y = ""
      ) +
      theme_minimal(base_size = 14)

    ggsave("outputs/figs/regression_coef.png", p2, width = 8, height = 6, dpi = 150)
    cat("✓ Regression analysis complete\n")
    cat("  → outputs/figs/regression_coef.png\n")
  }
} else {
  cat("⚠ Not enough data for regression (need >= 10 observations)\n")
}

cat("  → outputs/tables/regression_output.txt\n\n")

# ------------------------------------------------------------------------------
# 5. Word Frequency Analysis
# ------------------------------------------------------------------------------

cat("Step 5: Generating word frequency analysis...\n")

dfm_full <- dfm(tok_full)
word_freq <- textstat_frequency(dfm_full)

# Save top 20
write.csv(head(word_freq, 20), "outputs/tables/word_frequency.csv", row.names = FALSE)

# Plot
p3 <- word_freq %>%
  head(20) %>%
  ggplot(aes(x = reorder(feature, frequency), y = frequency)) +
  geom_col(fill = "#1f77b4") +
  coord_flip() +
  labs(
    title = "SOTU Top 20 高频词",
    x = NULL,
    y = "出现次数"
  ) +
  theme_minimal(base_size = 14)

ggsave("outputs/figs/word_frequency.png", p3, width = 8, height = 6, dpi = 150)

# Generate word cloud
library(quanteda.textplots)

png("outputs/figs/wordcloud.png", width = 800, height = 600, res = 150)
textplot_wordcloud(
  dfm_full,
  min_count = 2,
  max_words = 50,
  color = c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd")
)
dev.off()

cat("✓ Word frequency analysis complete\n")
cat("  → outputs/figs/word_frequency.png\n")
cat("  → outputs/figs/wordcloud.png\n")
cat("  → outputs/tables/word_frequency.csv\n\n")

# ------------------------------------------------------------------------------
# 6. Sample LLM Labels
# ------------------------------------------------------------------------------

cat("Step 6: Generating sample LLM labels...\n")

set.seed(313)
sample_sentences <- c(
  "We must defend our interests with decisive action.",
  "We welcome dialogue and cooperation with all nations.",
  "We will consider appropriate measures as circumstances permit.",
  "Our resolve is firm and our arsenal is strong.",
  "Together we can build a partnership for mutual benefit.",
  "It is relevant to note that conditions remain uncertain.",
  "Security requires constant vigilance and swift response.",
  "We respect the sovereignty of all peaceful nations.",
  "Properly managed, this situation need not escalate.",
  "Victory demands sacrifice and unwavering commitment."
)

sample_labels <- data.frame(
  sentence = sample_sentences,
  human_label = c("A", "B", "C", "A", "B", "C", "A", "B", "C", "A"),
  llm_label = c("A", "B", "C", "A", "B", "D", "A", "B", "C", "A"),
  stringsAsFactors = FALSE
)

jsonlite::write_json(
  sample_labels,
  "outputs/tables/sample_labels.jsonl",
  auto_unbox = TRUE
)

cat("✓ Sample LLM labels generated\n")
cat("  → outputs/tables/sample_labels.jsonl\n\n")

# ------------------------------------------------------------------------------
# 7. Summary Statistics
# ------------------------------------------------------------------------------

cat("Step 7: Generating summary statistics...\n")

# Data overview
data_summary <- data.frame(
  Metric = c("Total Documents", "Time Range", "Unique Presidents", "Unique Parties"),
  Value = c(
    nrow(d),
    paste(min(d$year, na.rm = TRUE), "-", max(d$year, na.rm = TRUE)),
    length(unique(d$president)),
    length(unique(d$party))
  )
)

write.csv(data_summary, "outputs/tables/data_summary.csv", row.names = FALSE)

cat("✓ Summary statistics saved\n")
cat("  → outputs/tables/data_summary.csv\n\n")

# ------------------------------------------------------------------------------
# Final Summary
# ------------------------------------------------------------------------------

cat("\n=== Pipeline Complete! ===\n\n")
cat("Generated outputs:\n")
cat("Figures:\n")
cat("  - outputs/figs/style_trends.png\n")
cat("  - outputs/figs/regression_coef.png\n")
cat("  - outputs/figs/word_frequency.png\n\n")
cat("Tables:\n")
cat("  - data/sotu.csv\n")
cat("  - outputs/tables/style_indices.csv\n")
cat("  - outputs/tables/regression_output.txt\n")
cat("  - outputs/tables/word_frequency.csv\n")
cat("  - outputs/tables/sample_labels.jsonl\n")
cat("  - outputs/tables/data_summary.csv\n\n")

cat("You can now render the slides with actual outputs!\n")
