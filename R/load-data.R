message("MEMORY USAGE load-data.R 1: ", ceiling(pryr::mem_used() / 1e6), " MB")

# Bulk RNA-seq data
# --------------------------------------------------------------------------

# Load: m log2tpm gene_symbols meta_colors
load("data/ITC_log2tpm_forShiny.rda")

# Mapping between Ensembl and Symbol
gene_symbols <- unlist(split(grad$GENE_NAME, grad$Row.names))

rownames(grad) <- grad$Row.names
grad$Row.names <- NULL

# Sanity check
stopifnot(all(m$sampleID == colnames(log2tpm)))

m$cell_type <- factor(
  x = m$cell_type,
  levels = c("CD4", "CD8", "MAIT", "NKT", "Vd1", "Vd2", "NK")
)

m_colors <- list(
  "cell_type" = c(
    "CD4"  = "#0072B2",
    "CD8"  = "#56B4E9",
    "MAIT" = "#009E73",
    "NKT"  = "#CC79A7",
    "Vd1"  = "#E69F00",
    "Vd2"  = "#D55E00",
    "NK"   = "#606060"
  ),
  "cluster" = c(
    
  )
)

fancy_celltypes <- c(
  "CD4"  = expression(paste("CD4" ^ "+", "T")),
  "CD8"  = expression(paste("CD8" ^ "+", "T")),
  "MAIT" = "MAIT",
  "NKT"  = "iNKT",
  "Vd1"  = expression(paste("V", delta, "1", sep = "")),
  "Vd2"  = expression(paste("V", delta, "2", sep = "")),
  "NK"   = "NK"
)

# Just the symbols
all_gene_symbols <- unname(gene_symbols)

# The default gene to plot
one_gene_symbol_default <- "TBX21"

message("MEMORY USAGE load-data.R 2: ", ceiling(pryr::mem_used() / 1e6), " MB")

#

# Single-cell RNA-seq data
# --------------------------------------------------------------------------

s <- environment()

# Read 4 datasets: bcell, tcell, mono, fibro
# Preprocess into a file for quick loading.
s$log2cpm_file <- "data/scrnaseq-log2tpm.h5"
s$log2cpm_dimnames_file <- "data/scrnaseq-log2tpm-dimnames.rda"
s$meta_file <- "data/scrnaseq-meta.rds"
if (file.exists(meta_file)) {
  meta <- readRDS(file = meta_file)
  # ffload(log2cpm_file, overwrite = TRUE)
  load(log2cpm_dimnames_file)
  s$log2cpm <- HDF5Array::HDF5Array(file = log2cpm_file, name = "log2cpm")
  load(log2cpm_dimnames_file, envir = s)
  rownames(s$log2cpm) <- s$log2cpm_rows
  colnames(s$log2cpm) <- s$log2cpm_cols
} else {
  s$meta <- data.table::fread("gzip -cd data/scITC_meta_data.txt.gz")
  s$meta$V1 <- NULL
  s$meta <- as.data.frame(s$meta)
  s$meta <- janitor::clean_names(s$meta)
  
  s$counts <- data.table::fread("gzip -cd data/scITC_counts.txt.gz")
  s$counts <- {
    retval <- as.matrix(s$counts[,2:ncol(s$counts)])
    rownames(retval) <- s$counts$V1
    retval
  }
  rm(retval)
  s$counts[is.na(s$counts)] <- 0
  s$log2cpm <- apply(counts, 2, function(x) log2(x / sum(x) * 1e6 + 1))
  
  stopifnot(all(s$meta$cell_id == colnames(s$counts)))
  
  saveRDS(s$meta, file = s$meta_file)
  s$log2cpm_rows <- rownames(s$log2cpm)
  s$log2cpm_cols <- colnames(s$log2cpm)
  save(
    envir = s,
    list = c("log2cpm_rows", "log2cpm_cols"),
    file = s$log2cpm_dimnames_file
  )
  s$log2cpm <- HDF5Array::writeHDF5Array(
    s$log2cpm, name = "log2cpm", file = s$log2cpm_file
  )
}

s$meta$cluster_number <- s$meta$cluster
# s$meta$cluster <- with(s$meta, sprintf("%s-%s", cell_type, cluster))
s$meta$cluster <- s$meta$cell_type

s$ix_include <- s$meta$cluster %in% names(which(table(s$meta$cluster) > 4))

s$meta$marker <- as.numeric(s$log2cpm[one_gene_symbol_default,])

message("MEMORY USAGE load-data.R 2: ", ceiling(pryr::mem_used() / 1e6), " MB")

# ggplot(s$meta[order(-s$meta$n_gene),]) +
#   aes(x = umap1, y = umap2, fill = n_gene) +
#   geom_point(size = 3, shape = 21, stroke = 0.1) +
#   scale_fill_viridis_c(trans = "log10") +
#   theme_bw(base_size = 20)

# hist(s$meta$n_gene, breaks = 100)

# --------------------------------------------------
# # Calculate %nonzero per protein marker per cytof cluster: line 572 to line 630
# protein_exp <- t(cytof_all[, c(1:35)])
# cell_clusters <- cytof_all$cluster
# 
# get_markers <- function(protein_exp, cell_clusters) {
#   # Compute statistics for each cluster.
#   dat_marker <- rbindlist(pblapply(
#     X = rownames(protein_exp),
#     cl = 2,
#     FUN = function(protein_name) {
#       protein  <- as.numeric(protein_exp[protein_name,])
#       rbindlist(lapply(unique(cell_clusters), function(cell_cluster) {
#         ix <- cell_clusters == cell_cluster
#         x <- protein[ix]
#         # x_mean <- mean(x)
#         # x_sd   <- sd(x)
#         x_pct_nonzero <- sum(x > 0) / length(x) 
#         # y <- protein[!ix]
#         # y_mean <- mean(y)
#         # y_sd   <- sd(y)
#         # y_pct_nonzero <- sum(y > 0) / length(y)
#         # test_w <- wilcox.test(x, y, alternative = "two.sided")
#         # test_t <- t.test(x, y, alternative = "two.sided")
#         data.frame(
#           "protein"              = protein_name,
#           "cluster"           = cell_cluster,
#           # "wilcox_pvalue"     = test_w$p.value,
#           # "ttest_pvalue"      = test_t$p.value,
#           # "auc"               = auroc(protein, ix),
#           "pct_nonzero"       = x_pct_nonzero
#           # "pct_nonzero_other" = y_pct_nonzero,
#           # "log2FC"            = x_mean - y_mean,
#           # "mean"              = x_mean,
#           # "sd"                = x_sd,
#           # "mean_other"        = y_mean,
#           # "sd_other"          = y_sd
#         )
#       }))
#     }
#   ))
#   # Check if the mean is highest in this cluster.
#   dat_marker[
#     ,
#     # mean_highest := mean >= max(mean),
#     by = protein
#     ]
#   dat_marker[
#     ,
#     # pct_nonzero_highest := pct_nonzero >= max(pct_nonzero),
#     by = protein
#     ]
#   return(dat_marker)
# }
# cytof_summarize <- get_markers(
#   protein_exp,
#   cell_clusters
# )
# cytof_summarize <- as.data.frame(cytof_summarize)
# cytof_summarize$pct_nonzero <- paste(round(cytof_summarize$pct_nonzero * 100, 2), "%", sep="")
# saveRDS(cytof_summarize, "cytof_summarize.rds")
