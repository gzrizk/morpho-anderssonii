#!/usr/bin/env Rscript
# make_poster_figures.R
# Generate the main figures for the study, with consistent colours and typography.
# Run from the repository root:
#   Rscript scripts/make_poster_figures.R
# Input/output directories can be overridden with RESULTS_DIR and FIG_DIR.

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(cowplot)
})

# ---------------------------------------------------------------------------
# Palette and typography
# ---------------------------------------------------------------------------
col_pat     <- "#0072B2"   # Patagonia blue
col_sha     <- "#D55E00"   # Shanxi orange
col_text    <- "#1A1A1A"
col_grid    <- "#D9D9D9"
col_accent  <- "#F2B705"   # logo yellow
font_family <- "Helvetica"

theme_poster <- function(base_size = 18) {
  theme_minimal(base_size = base_size, base_family = font_family) +
    theme(
      text = element_text(colour = col_text),
      axis.title = element_text(colour = col_text, face = "bold"),
      axis.text  = element_text(colour = col_text),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = col_grid, linewidth = 0.35),
      plot.margin = margin(4, 6, 4, 6)
    )
}

results_dir <- Sys.getenv("RESULTS_DIR", unset = "results")
out_dir     <- Sys.getenv("FIG_DIR", unset = "figures")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(results_dir, "tables"), showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------
shapes <- readRDS(file.path(results_dir, "arrays", "mean_shapes_tagged.rds"))
coords <- shapes$coords
group  <- factor(attr(coords, "collection_site"), levels = c("Patagonia", "Shanxi"))
csize  <- as.numeric(shapes$centroid_size)
n      <- dim(coords)[3]

# Specimen-by-variable matrix (rows = specimens; do not scramble the array!)
p <- dim(coords)[1] * dim(coords)[2]
X <- t(matrix(coords, nrow = p))
rownames(X) <- dimnames(coords)[[3]]
names(group) <- rownames(X)
stopifnot(identical(nrow(X), n))
stopifnot(isTRUE(all.equal(X[1, ], as.numeric(coords[, , 1]))))

pca <- prcomp(X, center = TRUE, scale. = FALSE)
pc  <- pca$x[, 1:2, drop = FALSE]
var <- 100 * pca$sdev^2 / sum(pca$sdev^2)

pca_df <- data.frame(
  PC1 = pc[, 1],
  PC2 = pc[, 2],
  Group = group,
  Specimen = rownames(X)
)

cent <- pca_df %>%
  group_by(Group) %>%
  summarise(PC1 = mean(PC1), PC2 = mean(PC2), .groups = "drop")

hull <- pca_df %>%
  group_by(Group) %>%
  slice(chull(PC1, PC2)) %>%
  ungroup()

fmt <- function(x, digits = 1) {
  sprintf(paste0("%.", digits, "f"), x)
}

# ---------------------------------------------------------------------------
# 1. Centroid size
# ---------------------------------------------------------------------------
size_df <- data.frame(csize = csize, Group = group)
size_sum <- size_df %>%
  group_by(Group) %>%
  summarise(mean = mean(csize), sd = sd(csize), .groups = "drop")

p_size <- ggplot(size_df, aes(x = Group, y = csize, fill = Group)) +
  geom_violin(width = 0.78, alpha = 0.45, colour = "grey25", linewidth = 0.5, trim = FALSE) +
  geom_boxplot(width = 0.13, alpha = 0.95, outlier.shape = NA,
               colour = "grey20", fill = "white") +
  geom_jitter(width = 0.075, size = 2.6, alpha = 0.75, colour = "grey15") +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 5.2,
               fill = "white", colour = "black", stroke = 1.1) +
  annotate("segment", x = 1, xend = 2, y = 51.5, yend = 51.5,
           colour = "grey25", linewidth = 0.7) +
  annotate("text", x = 1.5, y = 52.8, label = "p = 0.0003",
           family = font_family, size = 5.1, fontface = "bold") +
  annotate("text", x = 1, y = 57.0,
           label = paste0(fmt(size_sum$mean[1]), " \u00b1 ", fmt(size_sum$sd[1])),
           family = font_family, size = 4.4, fontface = "bold", colour = col_pat) +
  annotate("text", x = 2, y = 57.0,
           label = paste0(fmt(size_sum$mean[2]), " \u00b1 ", fmt(size_sum$sd[2])),
           family = font_family, size = 4.4, fontface = "bold", colour = col_sha) +
  scale_fill_manual(values = c(Patagonia = col_pat, Shanxi = col_sha)) +
  scale_y_continuous(limits = c(0, 60), expand = expansion(mult = c(0, 0.01))) +
  labs(x = NULL, y = "Centroid size") +
  theme_poster(20) +
  theme(legend.position = "none",
        axis.text.x = element_text(face = "bold", size = 21))

cairo_pdf(file.path(out_dir, "fig_size.pdf"),
          width = 6.8, height = 5.0, family = font_family)
print(p_size)
dev.off()

# ---------------------------------------------------------------------------
# 2. PCA morphospace
# ---------------------------------------------------------------------------
p_morpho <- ggplot(pca_df, aes(x = PC1, y = PC2, colour = Group, fill = Group)) +
  geom_polygon(data = hull, aes(group = Group, colour = Group), alpha = 0.28,
               linewidth = 0.7, inherit.aes = TRUE, show.legend = FALSE) +
  geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.3) +
  geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.3) +
  geom_point(size = 3.8, alpha = 0.85, stroke = 0) +
  geom_point(data = cent, aes(x = PC1, y = PC2),
             shape = 23, size = 7.2, fill = "white", colour = "black",
             stroke = 1.2, inherit.aes = FALSE) +
  scale_colour_manual(values = c(Patagonia = col_pat, Shanxi = col_sha)) +
  scale_fill_manual(values = c(Patagonia = col_pat, Shanxi = col_sha)) +
  coord_equal() +
  labs(x = paste0("PC1 (", fmt(var[1]), " %)"),
       y = paste0("PC2 (", fmt(var[2]), " %)")) +
  theme_poster(20) +
  theme(legend.position = "top",
        legend.title = element_blank(),
        legend.text = element_text(size = 18, face = "bold"),
        legend.key.height = unit(0.8, "lines"),
        legend.key.width = unit(1.1, "lines"))

cairo_pdf(file.path(out_dir, "fig_morphospace.pdf"),
          width = 6.8, height = 7.0, family = font_family)
print(p_morpho)
dev.off()

# ---------------------------------------------------------------------------
# 3. Shape differences between site means
# ---------------------------------------------------------------------------
m_pat <- matrix(as.numeric(apply(coords[, , group == "Patagonia", drop = FALSE], c(1, 2), mean)), ncol = 2)
m_sha <- matrix(as.numeric(apply(coords[, , group == "Shanxi", drop = FALSE], c(1, 2), mean)), ncol = 2)

smooth_idx <- function(M, idx, n = 220) {
  P <- M[idx, ]
  d <- c(0, cumsum(sqrt(rowSums(diff(P)^2))))
  cbind(
    spline(d, P[, 1], n = n, method = "natural")$y,
    spline(d, P[, 2], n = n, method = "natural")$y
  )
}

contour_idx <- c(1, 5:44, 2)
vein_idx    <- c(3, 45:59, 4)
xlim <- c(-0.225, 0.225)
ylim <- c(-0.155, 0.155)

cairo_pdf(file.path(out_dir, "fig_shape.pdf"),
          width = 6.8, height = 3.6, family = font_family)
par(mfrow = c(1, 2), mar = c(0.5, 0.5, 2.2, 0.5),
    family = font_family, cex.main = 1.05, xpd = NA)

# Panel A: site means overlaid
plot(m_pat, type = "n", asp = 1, axes = FALSE, xlab = "", ylab = "",
     xlim = xlim, ylim = ylim, main = "Site means")
polygon(smooth_idx(m_pat, contour_idx), col = adjustcolor(col_pat, 0.13),
        border = NA)
polygon(smooth_idx(m_sha, contour_idx), col = adjustcolor(col_sha, 0.13),
        border = NA)
lines(smooth_idx(m_pat, contour_idx), col = col_pat, lwd = 3)
lines(smooth_idx(m_sha, contour_idx), col = col_sha, lwd = 3)
lines(smooth_idx(m_pat, vein_idx), col = col_pat, lwd = 1.8, lty = 2)
lines(smooth_idx(m_sha, vein_idx), col = col_sha, lwd = 1.8, lty = 2)
legend("bottomright", legend = c("Patagonia", "Shanxi"),
       col = c(col_pat, col_sha), lwd = 3, bty = "n",
       cex = 0.85, seg.len = 1.4)

# Panel B: displacement of the Shanxi mean relative to Patagonia
plot(m_pat, type = "n", asp = 1, axes = FALSE, xlab = "", ylab = "",
     xlim = xlim, ylim = ylim,
     main = "Shanxi \u2212 Patagonia")
lines(smooth_idx(m_pat, contour_idx), col = "grey55", lwd = 1.4)
lines(smooth_idx(m_pat, vein_idx), col = "grey55", lwd = 1.4)
arrows(m_pat[, 1], m_pat[, 2],
       m_pat[, 1] + 3 * (m_sha[, 1] - m_pat[, 1]),
       m_pat[, 2] + 3 * (m_sha[, 2] - m_pat[, 2]),
       length = 0.045, col = col_sha, lwd = 1.0)
mtext("Vectors \u00d73", side = 1, line = -1.4, adj = 0.98,
      cex = 0.72, col = "grey35", family = font_family)

dev.off()

# ---------------------------------------------------------------------------
# 4. Landmark scheme
# ---------------------------------------------------------------------------
mean_shape <- matrix(as.numeric(apply(coords, c(1, 2), mean)), ncol = 2)

cairo_pdf(file.path(out_dir, "fig_landmarks.pdf"),
          width = 6.8, height = 4.4, family = font_family)
par(mar = c(0.4, 0.4, 0.8, 0.4), family = font_family)
plot(mean_shape, type = "n", asp = 1, axes = FALSE, xlab = "", ylab = "",
     xlim = xlim, ylim = ylim)
polygon(smooth_idx(mean_shape, contour_idx), col = adjustcolor("grey85", 0.55),
        border = NA)
lines(smooth_idx(mean_shape, contour_idx), col = "#333333", lwd = 2.4)
lines(smooth_idx(mean_shape, vein_idx), col = "#2166AC", lwd = 2.0)
points(mean_shape[-c(1:4), 1], mean_shape[-c(1:4), 2],
       pch = 19, cex = 0.45, col = "#333333")
points(mean_shape[1:4, 1], mean_shape[1:4, 2],
       pch = 21, cex = 3.0, bg = col_accent, col = "black", lwd = 1.4)
text(mean_shape[1:4, 1], mean_shape[1:4, 2], labels = 1:4,
     pos = 4, offset = 0.5, cex = 1.25, font = 2, family = font_family)
text(0.145, 0.105, "outline\n(40 semilandmarks)", cex = 0.78,
     col = "#333333", family = font_family, font = 2)
text(0.045, 0.020, "midvein\n(15 semilandmarks)", cex = 0.78,
     col = "#2166AC", family = font_family, font = 2)
legend("bottomleft", legend = c("Fixed landmark", "Semilandmark"),
       pch = c(21, 19), pt.bg = c(col_accent, "#333333"),
       col = c("black", "#333333"), pt.cex = c(1.8, 0.8),
       bty = "n", cex = 0.78)
dev.off()

# ---------------------------------------------------------------------------
# 5. Permutation test
# ---------------------------------------------------------------------------
perm <- read.csv(file.path(results_dir, "tables", "perm_centroid_distances.csv"))$x
obs  <- read.csv(file.path(results_dir, "tables", "distances_between_centroids.csv"))$d_shape

perm_df <- data.frame(d = perm)
p_perm <- ggplot(perm_df, aes(x = d)) +
  geom_histogram(bins = 38, fill = "grey72", colour = "white", linewidth = 0.25) +
  geom_vline(xintercept = obs, colour = col_sha, linewidth = 1.25) +
  annotate("text", x = obs, y = Inf, label = paste0("D = ", fmt(obs, 3)),
           hjust = 1.08, vjust = 1.6, family = font_family,
           fontface = "bold", size = 4.8, colour = col_sha) +
  annotate("text", x = obs, y = Inf, label = "p < 0.001",
           hjust = 1.08, vjust = 3.4, family = font_family,
           fontface = "bold", size = 4.8, colour = col_sha) +
  labs(x = "Procrustes distance between means", y = "Frequency") +
  theme_poster(18)

cairo_pdf(file.path(out_dir, "fig_permutation.pdf"),
          width = 6.8, height = 4.1, family = font_family)
print(p_perm)
dev.off()

# ---------------------------------------------------------------------------
# 6. LOOCV: classification and confusion matrix
# ---------------------------------------------------------------------------
# X already has one row per specimen (mean of its 3 pinnae); the whole
# specimen is held out, not a single pinna.
stopifnot(identical(rownames(X), dimnames(coords)[[3]]))
pred <- setNames(character(n), rownames(X))
for (i in rownames(X)) {
  idx <- setdiff(rownames(X), i)
  cents <- sapply(levels(group), function(g) {
    colMeans(X[idx[group[idx] == g], , drop = FALSE])
  })
  d <- apply(cents, 2, function(cc) sqrt(sum((X[i, ] - cc)^2)))
  pred[i] <- names(which.min(d))
}
pred <- factor(pred, levels = levels(group))
acc <- mean(pred == group)
tab <- table(observed = group, predicted = pred)

pca_df$Pred <- pred[pca_df$Specimen]
pca_df$Status <- ifelse(pca_df$Pred == pca_df$Group, "Correct", "Error")
mis <- which(pred != group)
cat("LOOCV errors:", length(mis), "->", rownames(X)[mis], "\n")

p_loocv_scatter <- ggplot(pca_df, aes(x = PC1, y = PC2, colour = Group, fill = Group)) +
  geom_polygon(data = hull, aes(group = Group, colour = Group), alpha = 0.20,
               linewidth = 0.5, inherit.aes = TRUE, show.legend = FALSE) +
  geom_point(size = 2.8, alpha = 0.75, stroke = 0) +
  geom_point(data = pca_df[mis, , drop = FALSE],
             aes(x = PC1, y = PC2), shape = 21, size = 7.4,
             fill = NA, colour = "black", stroke = 1.5, inherit.aes = FALSE) +
  scale_colour_manual(values = c(Patagonia = col_pat, Shanxi = col_sha)) +
  scale_fill_manual(values = c(Patagonia = col_pat, Shanxi = col_sha)) +
  coord_equal() +
  labs(x = paste0("PC1 (", fmt(var[1]), " %)"),
       y = paste0("PC2 (", fmt(var[2]), " %)")) +
  theme_poster(15) +
  theme(legend.position = "none")

cm_df <- as.data.frame(tab)
cm_df$observed <- factor(cm_df$observed, levels = levels(group))
cm_df$predicted <- factor(cm_df$predicted, levels = levels(group))

p_cm <- ggplot(cm_df, aes(x = predicted, y = observed, fill = Freq)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = Freq), family = font_family, fontface = "bold",
            size = 8, colour = "white") +
  scale_fill_gradient(low = "#9ECAE1", high = col_pat, limits = c(0, 20)) +
  scale_y_discrete(limits = rev(levels(group))) +
  labs(x = "Predicted", y = "Observed",
       title = paste0("LOOCV: ", sum(diag(tab)), "/", n,
                      "\n(", fmt(acc * 100), " %)")) +
  theme_poster(15) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", size = 17, hjust = 0.5),
        axis.text.x = element_text(angle = 0, face = "bold"),
        axis.text.y = element_text(face = "bold"))

p_loocv <- plot_grid(p_loocv_scatter, p_cm, nrow = 1,
                     labels = c("A", "B"), label_size = 20,
                     rel_widths = c(1.25, 1))

cairo_pdf(file.path(out_dir, "fig_loocv.pdf"),
          width = 6.8, height = 4.2, family = font_family)
print(p_loocv)
dev.off()

# ---------------------------------------------------------------------------
# 7. Numeric summary
# ---------------------------------------------------------------------------
pred_df <- data.frame(Specimen = rownames(X), Observed = group, Predicted = pred)
write.csv(pred_df, file.path(results_dir, "tables", "loocv_predictions.csv"),
          row.names = FALSE)
write.csv(as.data.frame(tab), file.path(results_dir, "tables", "loocv_confusion.csv"),
          row.names = FALSE)

cat("\nSummary\n")
cat("PC1:", fmt(var[1]), "%  PC2:", fmt(var[2]), "%  total:", fmt(var[1] + var[2]), "%\n")
cat("Centroid size Patagonia:", fmt(size_sum$mean[1]), "+-", fmt(size_sum$sd[1]),
    "  Shanxi:", fmt(size_sum$mean[2]), "+-", fmt(size_sum$sd[2]), "\n")
cat("Observed distance:", fmt(obs, 4), "  p < 0.001\n")
cat("LOOCV:", sum(diag(tab)), "/", n, " = ", fmt(acc * 100), "%\n")
print(tab)

cat("\nFigures written to:", out_dir, "\n")
