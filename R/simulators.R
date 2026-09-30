# ---------------------------------------------------------------------------
# Movement simulators shared by Sessions 5, 6 and 7.
#
# Session 5 builds these step by step; Sessions 6 and 7 `source()` this file
# so that the "ground truth" animal is the same one everywhere.
# Base R + `circular` only.
# ---------------------------------------------------------------------------

# von Mises draws as plain numbers in (-pi, pi]
rvm <- function(n, mu = 0, kappa = 1) {
  if (n == 0) return(numeric(0))
  a <- as.numeric(circular::rvonmises(n, circular::circular(mu), kappa))
  atan2(sin(a), cos(a))
}

# Correlated random walk: gamma step lengths, von Mises turning angles.
# kappa = 0 gives an uncorrelated (Brownian-like) walk.
simulate_crw <- function(n, shape = 2, scale = 250, kappa = 2,
                         start = c(0, 0), heading0 = 0) {
  turn    <- rvm(n - 1, 0, kappa)
  heading <- cumsum(c(heading0, turn))
  sl      <- rgamma(n, shape = shape, scale = scale)
  data.frame(step = seq_len(n),
             x = start[1] + cumsum(sl * cos(heading)),
             y = start[2] + cumsum(sl * sin(heading)),
             sl = sl, heading = heading)
}

# Biased correlated random walk towards a point `goal`.
# Each new heading is a von Mises draw centred on a weighted circular mean of
# the previous heading (persistence) and the bearing to the goal (bias).
# w = 0 -> pure CRW; w = 1 -> pure bias.
simulate_bcrw <- function(n, goal = c(0, 0), w = 0.3, shape = 2, scale = 250,
                          kappa = 2, start = c(5000, 5000), heading0 = 0) {
  x <- y <- sl <- heading <- numeric(n)
  pos <- start; h <- heading0
  for (i in seq_len(n)) {
    bearing <- atan2(goal[2] - pos[2], goal[1] - pos[1])
    mu <- atan2((1 - w) * sin(h) + w * sin(bearing),
                (1 - w) * cos(h) + w * cos(bearing))
    h <- rvm(1, mu, kappa)
    s <- rgamma(1, shape = shape, scale = scale)
    pos <- pos + s * c(cos(h), sin(h))
    x[i] <- pos[1]; y[i] <- pos[2]; sl[i] <- s; heading[i] <- h
  }
  data.frame(step = seq_len(n), x, y, sl, heading)
}

# The "ground-truth animal" for Session 6: a central-place BCRW, sampled
# every step (think: every 20 minutes). Deterministic given the seed.
truth_animal <- function(n = 5000, seed = 2026) {
  set.seed(seed)
  simulate_bcrw(n, goal = c(0, 0), w = 0.08, shape = 2, scale = 150,
                kappa = 1.5, start = c(0, 0))
}

# Session 7: an animal that moves with the same kernel but *chooses* among
# `n_candidates` possible next steps with probability ∝ exp(beta * habitat).
# This is exactly the generative model an SSF assumes, so the fitted
# coefficient should recover `beta`.
simulate_ssf <- function(n, habitat, beta = 1.5, n_candidates = 30,
                         shape = 2, scale = 150, kappa = 1, start = NULL,
                         seed = 7) {
  set.seed(seed)
  if (is.null(start)) start <- as.numeric(terra::crds(terra::spatSample(
    habitat, 1, method = "regular", as.points = TRUE)))
  x <- y <- numeric(n); pos <- start; h <- 0
  for (i in seq_len(n)) {
    ta <- rvm(n_candidates, 0, kappa)
    sl <- rgamma(n_candidates, shape = shape, scale = scale)
    hh <- h + ta
    cand <- cbind(pos[1] + sl * cos(hh), pos[2] + sl * sin(hh))
    hab  <- terra::extract(habitat, cand)[, 1]
    wts  <- exp(beta * hab); wts[is.na(wts)] <- 0
    if (sum(wts) == 0) wts[] <- 1
    k <- sample.int(n_candidates, 1, prob = wts)
    pos <- cand[k, ]; h <- hh[k]
    x[i] <- pos[1]; y[i] <- pos[2]
  }
  data.frame(step = seq_len(n), x, y)
}

# A smooth, standardised habitat surface (Gaussian random field by smoothing
# white noise). Units: metres, local projected CRS.
simulate_habitat <- function(size = 20000, res = 50, smooth = 15, seed = 11) {
  set.seed(seed)
  n <- size / res
  r <- terra::rast(nrows = n, ncols = n, xmin = -size / 2, xmax = size / 2,
                   ymin = -size / 2, ymax = size / 2, crs = "local")
  terra::values(r) <- rnorm(terra::ncell(r))
  w <- terra::focalMat(r, smooth * res, type = "Gauss")
  r <- terra::focal(r, w, fun = "sum", na.rm = TRUE)
  r <- (r - terra::global(r, "mean", na.rm = TRUE)[[1]]) /
        terra::global(r, "sd", na.rm = TRUE)[[1]]
  names(r) <- "habitat"
  r
}

# The ground-truth animal's movement rule, as a list, so every script uses
# exactly the same parameters.
truth_rule <- list(goal = c(0, 0), w = 0.08, shape = 2, scale = 150,
                   kappa = 1.5, start = c(0, 0))

# True area of the ground-truth animal's utilisation distribution: simulate
# a very long run and take the highest-density region containing `level` of
# the positions, on a fine grid. With 200,000 steps the run crosses its range
# hundreds of times, so this is close to the exact long-run answer.
truth_area <- function(level = 0.95, n = 2e5, seed = 99, res = 100) {
  set.seed(seed)
  long <- do.call(simulate_bcrw, c(list(n = n), truth_rule))
  ext <- ceiling(max(abs(c(long$x, long$y))) / 1000) * 1000 + res
  r <- terra::rast(xmin = -ext, xmax = ext, ymin = -ext, ymax = ext, res = res)
  cnt <- terra::rasterize(cbind(long$x, long$y), r, fun = "length", background = 0)
  v <- sort(terra::values(cnt)[, 1], decreasing = TRUE)
  sum(cumsum(v) / sum(v) <= level) * res^2 / 1e6          # km²
}
