# ==============================================================================
# Collocation Network Generator
# ==============================================================================
# This script generates bigram collocation networks from SOTU corpus
# and exports both data tables and visualization figures
#
# Author: Adrian Sun
# Date: 2025-10-13
# ==============================================================================

make_collocation_graph <- function(
    data_path = "data/sotu.csv",
    output_dir = "outputs",
    decades = c("1940s", "1990s"),
    min_count = 3,
    top_n = 50
) {

  # Load required packages
  required_pkgs <- c("quanteda", "quanteda.textstats", "igraph", "ggplot2", "dplyr", "readr")
  for (pkg in required_pkgs) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      stop("Package '", pkg, "' is required. Install with: install.packages('", pkg, "')")
    }
  }

  # Create output directories
  dir.create(file.path(output_dir, "figs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(output_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

  # Read data
  message("→ Reading data from: ", data_path)
  d <- readr::read_csv(data_path, show_col_types = FALSE)
  d$decade <- paste0(floor(d$year / 10) * 10, "s")

  # Process each decade
  for (dec in decades) {
    message("\n→ Processing decade: ", dec)

    # Filter data for this decade
    d_decade <- d[d$decade == dec, ]
    message("  → ", nrow(d_decade), " documents in ", dec)

    # Create corpus and tokens
    corp <- quanteda::corpus(d_decade, text_field = "text")
    tok <- quanteda::tokens(corp, remove_punct = TRUE, remove_numbers = TRUE) |>
      quanteda::tokens_remove(quanteda::stopwords("en")) |>
      quanteda::tokens_remove(c("will", "must", "can", "may", "shall")) |>
      quanteda::tokens_tolower()

    # Calculate collocations
    message("  → Calculating collocations...")
    colls <- quanteda.textstats::textstat_collocations(
      tok,
      size = 2:3,
      min_count = min_count
    )

    # Sort by lambda and take top N
    colls <- colls[order(-colls$lambda), ]
    colls_top <- head(colls, top_n)

    # Save collocation table
    table_path <- file.path(output_dir, "tables", paste0("collocations_", dec, ".csv"))
    write.csv(colls_top, table_path, row.names = FALSE)
    message("  ✓ Saved collocation table: ", table_path)

    # Create network graph
    message("  → Building network graph...")

    # Extract bigrams only for network visualization
    colls_bigram <- colls_top[colls_top$length == 2, ]

    if (nrow(colls_bigram) > 0) {
      # Parse collocation into source and target
      edges <- do.call(rbind, strsplit(colls_bigram$collocation, " "))
      edge_list <- data.frame(
        from = edges[, 1],
        to = edges[, 2],
        weight = colls_bigram$count,
        lambda = colls_bigram$lambda,
        stringsAsFactors = FALSE
      )

      # Create igraph object
      g <- igraph::graph_from_data_frame(edge_list, directed = FALSE)

      # Calculate network metrics
      density_val <- igraph::edge_density(g)
      clustering_val <- igraph::transitivity(g, type = "average")
      communities <- igraph::cluster_louvain(g)
      largest_community <- max(table(igraph::membership(communities))) / igraph::vcount(g)

      message("  ✓ Network metrics:")
      message("    - Density: ", round(density_val, 4))
      message("    - Avg clustering: ", round(clustering_val, 4))
      message("    - Largest community: ", round(largest_community * 100, 2), "%")

      # Save network metrics
      metrics <- data.frame(
        decade = dec,
        density = density_val,
        avg_clustering = clustering_val,
        largest_community_pct = largest_community * 100
      )
      metrics_path <- file.path(output_dir, "tables", paste0("network_metrics_", dec, ".csv"))
      write.csv(metrics, metrics_path, row.names = FALSE)

      # Plot network
      message("  → Plotting network...")

      # Set layout
      set.seed(313)
      layout <- igraph::layout_with_fr(g)

      # Set vertex attributes
      igraph::V(g)$size <- log(igraph::degree(g) + 1) * 3 + 5
      igraph::V(g)$color <- igraph::membership(communities)
      igraph::V(g)$label.cex <- 0.7
      igraph::V(g)$label.color <- "black"

      # Set edge attributes
      igraph::E(g)$width <- log(igraph::E(g)$weight + 1) * 0.5

      # Create plot
      fig_path <- file.path(output_dir, "figs", paste0("network_", dec, ".png"))
      png(fig_path, width = 1200, height = 1000, res = 150)
      par(mar = c(1, 1, 3, 1))
      plot(
        g,
        layout = layout,
        main = paste0("Collocation Network: ", dec),
        vertex.label.dist = 0.5,
        edge.curved = 0.2
      )
      dev.off()
      message("  ✓ Saved network plot: ", fig_path)

    } else {
      message("  ✗ No bigrams found for network visualization")
    }
  }

  message("\n✓ Collocation analysis complete!")
  return(invisible(TRUE))
}

# Run the function if script is sourced
if (sys.nframe() == 0) {
  make_collocation_graph()
}
