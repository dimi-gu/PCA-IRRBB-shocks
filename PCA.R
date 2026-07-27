## ============================================================
## Yearly overlapping differences of the EUR AAA spot curve
## r(t, mat) - r(t - 1y, mat)  for every business date t and every tenor
## ============================================================

input_file  <- "ecb_aaa_spot_yield_curve_2026-07-24.csv"
output_file <- "yearly_overlapping_diffs.csv"

df <- read.csv(input_file, stringsAsFactors = FALSE, check.names = FALSE)
df$Date <- as.Date(df$Date)
df <- df[order(df$Date), ]

tenor_cols <- setdiff(names(df), "Date")
dates      <- df$Date

## Target lookback date = t - 365 calendar days
target_dates <- dates - 365

## findInterval gives, for each target date, the position of the last
## available business date <= target date (0 = no such date exists yet)
match_idx <- findInterval(target_dates, dates)
match_idx[match_idx == 0] <- NA

matched_dates <- dates[match_idx]              # NA propagates automatically
gap_days      <- as.numeric(target_dates - matched_dates)

## Business dates are at most ~6 calendar days apart (weekends/holidays),
## so require the matched date to be within 10 days of the ideal target;
## otherwise there's no real "1 year ago" observation to use.
max_gap_tolerance <- 10
match_idx[!is.na(gap_days) & gap_days > max_gap_tolerance] <- NA

## Compute the overlapping yearly difference for every tenor
diffs <- as.data.frame(
  sapply(tenor_cols, function(col) df[[col]] - df[[col]][match_idx])
)
names(diffs) <- tenor_cols

result <- data.frame(
  Date            = dates,
  Lag_Date        = as.Date(ifelse(is.na(match_idx), NA, matched_dates), origin = "1970-01-01"),
  Gap_Days        = ifelse(is.na(match_idx), NA, gap_days)
)
result <- cbind(result, diffs)

## Drop rows with no valid 1-year lookback (insufficient history at series start)
result <- result[!is.na(match_idx), ]

write.csv(result, output_file, row.names = FALSE)

cat("Rows kept (valid 1y diff):", nrow(result), "\n")
cat("Rows dropped (insufficient 1y history):", sum(is.na(match_idx)), "\n")
cat("First diff date:", format(min(result$Date)), "\n")
cat("Gap_days summary (days between t-365 and matched date):\n")
print(summary(result$Gap_Days))
cat("\nPreview:\n")
print(head(result[, c("Date","Lag_Date","Gap_Days","1M","1Y","10Y","30Y")], 5), check.names = FALSE)


## ============================================================
## PCA (3 components) on yearly overlapping term structure shifts
## ============================================================

diffs_file <- "yearly_overlapping_diffs.csv"

df <- read.csv(diffs_file, stringsAsFactors = FALSE, check.names = FALSE)
df$Date     <- as.Date(df$Date)
df$Lag_Date <- as.Date(df$Lag_Date)

tenor_cols <- setdiff(names(df), c("Date", "Lag_Date", "Gap_Days"))

X <- as.matrix(df[, tenor_cols])

## Standardized PCA (correlation matrix): each tenor's yearly shift series
## is centered and scaled to unit variance before extracting components,
## consistent with the "standardized yearly shifts" convention used earlier.
pca <- prcomp(X, center = TRUE, scale. = TRUE)

n_comp <- 3
loadings <- pca$rotation[, 1:n_comp]
scores   <- pca$x[, 1:n_comp]

var_explained <- (pca$sdev^2 / sum(pca$sdev^2))[1:n_comp]
cat("Variance explained by PC1-3:\n")
print(round(var_explained * 100, 2))
cat("Cumulative:", round(sum(var_explained) * 100, 2), "%\n\n")

## ---- Map tenor labels to numeric years for the x-axis ----
tenor_to_years <- function(tenors) {
  sapply(tenors, function(t) {
    if (grepl("M$", t)) as.numeric(sub("M$", "", t)) / 12
    else as.numeric(sub("Y$", "", t))
  })
}
maturities <- tenor_to_years(tenor_cols)
ord <- order(maturities)

## ---- Save loadings and scores ----
loadings_out <- data.frame(Tenor = tenor_cols, Maturity_Years = maturities, loadings)
write.csv(loadings_out, "pca_loadings.csv", row.names = FALSE)

scores_out <- data.frame(Date = df$Date, scores)
write.csv(scores_out, "pca_scores.csv", row.names = FALSE)

## Set to TRUE if you also want PNG copies saved to disk (in addition to
## the plots appearing in RStudio's Plots pane)
save_png <- TRUE

cols <- c("steelblue", "darkorange", "forestgreen")

plot_loadings <- function() {
  plot(maturities[ord], loadings[ord, 1], type = "b", pch = 16, col = cols[1],
       ylim = range(loadings), xlab = "Maturity (years)", ylab = "Loading",
       main = "PCA loadings by tenor -- standardized yearly shifts (R)")
  lines(maturities[ord], loadings[ord, 2], type = "b", pch = 16, col = cols[2])
  lines(maturities[ord], loadings[ord, 3], type = "b", pch = 16, col = cols[3])
  abline(h = 0, col = "grey40", lty = 2)
  legend("topright", legend = c("PC1", "PC2", "PC3"), col = cols, lty = 1, pch = 16, bty = "n")
  grid()
}

plot_scores <- function() {
  plot(df$Date, scores[, 1], type = "l", col = cols[1],
       ylim = range(scores), xlab = "Date", ylab = "PC score",
       main = "History of PCA scores (R)")
  lines(df$Date, scores[, 2], col = cols[2])
  lines(df$Date, scores[, 3], col = cols[3])
  abline(h = 0, col = "grey40", lty = 2)
  legend("topright", legend = c("PC1", "PC2", "PC3"), col = cols, lty = 1, bty = "n")
  grid()
}

## ---- Plot 1: PCA loadings by tenor (shows in RStudio Plots pane) ----
plot_loadings()

## ---- Plot 2: History of PCA scores (shows in RStudio Plots pane) ----
plot_scores()

## ---- Optional: also save PNG copies ----
if (save_png) {
  png("pca_loadings.png", width = 1400, height = 900, res = 130); plot_loadings(); dev.off()
  png("pca_scores.png",   width = 1400, height = 900, res = 130); plot_scores();   dev.off()
  cat("Saved PNGs: pca_loadings.png, pca_scores.png\n")
}

cat("Saved CSVs: pca_loadings.csv, pca_scores.csv\n")