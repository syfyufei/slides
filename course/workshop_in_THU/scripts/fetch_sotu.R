# ==============================================================================
# SOTU Data Fetcher
# ==============================================================================
# This script fetches State of the Union (SOTU) corpus data from quanteda
# and exports it as a CSV file for use in the Discourse NLP Lecture
#
# Author: Adrian Sun
# Date: 2025-10-13
# ==============================================================================

fetch_sotu <- function(output_path = "data/sotu.csv", force = FALSE) {

  # Check if file already exists
  if (file.exists(output_path) && !force) {
    message("✓ Data file already exists at: ", output_path)
    message("  Use force=TRUE to re-download")
    return(invisible(TRUE))
  }

  # Ensure output directory exists
  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message("✓ Created output directory: ", output_dir)
  }

  # Load required packages
  if (!require("quanteda", quietly = TRUE)) {
    stop("Package 'quanteda' is required. Install with: install.packages('quanteda')")
  }

  message("→ Fetching SOTU corpus from quanteda...")

  # Helper to safely extract docvars with flexible naming
  get_docvar <- function(doc_df, candidates) {
    for (field in candidates) {
      if (field %in% names(doc_df)) {
        return(doc_df[[field]])
      }
    }
    stop("field(s) ", paste(candidates, collapse = "/"), " not found")
  }

  # Try to fetch from quanteda official RDS
  tryCatch({
    sotu <- readRDS(url("https://quanteda.org/data/data_corpus_sotu.rds"))
    message("✓ Successfully downloaded SOTU corpus")

    # Extract data
    doc_df <- unclass(sotu)$documents

    d <- data.frame(
      date = get_docvar(doc_df, c("Date", "date")),
      president = get_docvar(doc_df, c("President", "president")),
      party = get_docvar(doc_df, c("Party", "party")),
      text = get_docvar(doc_df, c("texts", "text")),
      stringsAsFactors = FALSE
    )

    d$president <- as.character(d$president)
    d$party <- as.character(d$party)
    d$text <- as.character(d$text)

    # Add year variable for convenience
    d$year <- as.integer(format(as.Date(d$date), "%Y"))

    # Write to CSV
    write.csv(d, output_path, row.names = FALSE, fileEncoding = "UTF-8")
    message("✓ Data saved to: ", output_path)
    message("  → ", nrow(d), " documents from ", min(d$year, na.rm = TRUE), " to ", max(d$year, na.rm = TRUE))

    return(invisible(TRUE))

  }, error = function(e) {
    message("✗ Failed to download from quanteda.org")
    message("  Error: ", e$message)
    message("\n→ Trying alternative method: quanteda.corpora package...")

    # Try alternative: quanteda.corpora package
    tryCatch({
      if (!require("quanteda.corpora", quietly = TRUE)) {
        message("✗ Package 'quanteda.corpora' not found")
        message("\n══════════════════════════════════════════════════════════════")
        message("OFFLINE MODE INSTRUCTIONS:")
        message("══════════════════════════════════════════════════════════════")
        message("1. Install quanteda.corpora:")
        message("   devtools::install_github('quanteda/quanteda.corpora')")
        message("\n2. Or manually download SOTU data and place in:")
        message("   ", output_path)
        message("\n3. Update YAML parameter: data_source: 'csv'")
        message("══════════════════════════════════════════════════════════════\n")
        return(invisible(FALSE))
      }

      data(data_corpus_sotu, package = "quanteda.corpora")
      sotu2 <- data_corpus_sotu

      doc_df2 <- unclass(sotu2)$documents

      d <- data.frame(
        date = get_docvar(doc_df2, c("Date", "date")),
        president = get_docvar(doc_df2, c("President", "president")),
        party = get_docvar(doc_df2, c("Party", "party")),
        text = get_docvar(doc_df2, c("texts", "text")),
        stringsAsFactors = FALSE
      )

      d$president <- as.character(d$president)
      d$party <- as.character(d$party)
      d$text <- as.character(d$text)

      d$year <- as.integer(format(as.Date(d$date), "%Y"))

      write.csv(d, output_path, row.names = FALSE, fileEncoding = "UTF-8")
      message("✓ Data saved to: ", output_path)
      message("  → ", nrow(d), " documents from ", min(d$year, na.rm = TRUE), " to ", max(d$year, na.rm = TRUE))

      return(invisible(TRUE))

    }, error = function(e2) {
      message("✗ Failed to load from quanteda.corpora package")
      message("  Error: ", e2$message)
      message("\n══════════════════════════════════════════════════════════════")
      message("Please check your internet connection or install quanteda.corpora")
      message("══════════════════════════════════════════════════════════════\n")
      return(invisible(FALSE))
    })
  })
}

# Run the function if script is sourced
if (sys.nframe() == 0) {
  fetch_sotu()
}
