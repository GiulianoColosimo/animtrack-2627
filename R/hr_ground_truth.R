# ---------------------------------------------------------------------------
# Session 6 — how well do home-range estimators recover a KNOWN home range?
#
# Simulates `n_rep` independent "ground-truth animals" (the central-place
# walker from Session 5), samples each hourly for ~69 days, estimates the 95%
# home range five ways, and compares each estimate with the true area.
#
# Takes ~15-20 minutes. Results are saved to data/hr_ground_truth.csv so the
# practical can plot them instantly. Rerun with:
#     Rscript R/hr_ground_truth.R
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(sf); library(dplyr); library(sp)
  library(adehabitatHR); library(adehabitatLT); library(ctmm)
})
source("R/simulators.R")

n_rep <- 20
true95 <- truth_area(0.95)
message("True 95% area: ", round(true95), " km2")

one_rep <- function(seed) {
  set.seed(seed)
  tr  <- do.call(simulate_bcrw, c(list(n = 5000), truth_rule))  # 20-min steps
  obs <- tr[seq(1, nrow(tr), by = 3), ]                          # hourly fixes
  obs$t <- as.POSIXct("2026-01-01", tz = "UTC") + (obs$step - 1) * 20 * 60

  pts <- SpatialPoints(obs[, c("x", "y")])
  mcp  <- mcp.area(pts, percent = 95, unout = "km2", plotit = FALSE)[[1]]
  href <- kernel.area(kernelUD(pts, h = "href", grid = 200, extent = 1),
                      percent = 95, unout = "km2")[[1]]
  lscv <- kernel.area(suppressWarnings(kernelUD(pts, h = "LSCV", grid = 200, extent = 1)),
                      percent = 95, unout = "km2")[[1]]

  ltr <- as.ltraj(obs[, c("x", "y")], date = obs$t, id = "sim")
  lk  <- liker(ltr, sig2 = 10, rangesig1 = c(0.1, 50), plotit = FALSE)
  bb  <- kernel.area(kernelbb(ltr, sig1 = lk$sim$sig1, sig2 = 10, grid = 150, extent = 0.5),
                     percent = 95, unout = "km2")[[1]]

  # ctmm wants geographic coordinates: park the animal in UTM 36S and convert
  ll <- st_coordinates(st_transform(
    st_as_sf(data.frame(x = obs$x + 4e5, y = obs$y + 7.3e6), coords = c("x", "y"), crs = 32736),
    4326))
  tel <- suppressMessages(as.telemetry(data.frame(
    timestamp = obs$t, location.long = ll[, 1], location.lat = ll[, 2],
    individual.local.identifier = "sim"), timeformat = "auto"))
  fit <- ctmm.select(tel, ctmm.guess(tel, interactive = FALSE))
  ci  <- summary(akde(tel, fit), units = FALSE)$CI / 1e6

  data.frame(rep = seed, MCP = mcp, KDE_href = href, KDE_LSCV = lscv, BBMM = bb,
             AKDE = ci[2], AKDE_low = ci[1], AKDE_high = ci[3], true95 = true95)
}

res <- bind_rows(lapply(seq_len(n_rep), function(i) { message("rep ", i); one_rep(i) }))
write.csv(res, "data/hr_ground_truth.csv", row.names = FALSE)
message("Saved data/hr_ground_truth.csv")
