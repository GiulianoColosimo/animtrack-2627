# ---------------------------------------------------------------------------
# Shared by the slide decks: colours, graphics settings and the cleaned course
# data. The practicals build all of this step by step; the slides only need
# the results, so they `source()` this file in a hidden setup chunk.
# ---------------------------------------------------------------------------

teal  <- "#1f6f78"
rust  <- "#c1440e"
gold  <- "#b8860b"
light <- "#6fc3cd"
ink   <- "grey20"
faint <- "grey75"

# Base-graphics settings sized for a 1280 x 760 slide: axis labels and titles
# come out close to the slide's body text.
slide_par <- function(...) {
  par(mar = c(4.6, 5.2, 3.2, 1), cex.lab = 1.6, cex.axis = 1.35, cex.main = 1.8,
      font.main = 1, las = 1, bty = "l", mgp = c(3.2, 0.8, 0), ...)
}

# A blank panel for maps: equal aspect, no axes
map_par <- function(...) {
  par(mar = c(0.5, 0.5, 3.2, 0.5), cex.main = 1.8, font.main = 1, ...)
}

# A scale bar for projected maps; `unit` = map units per km (1000 for metres)
scale_bar <- function(km, unit = 1000, pos = c(0.06, 0.06), lwd = 4, cex = 1.4) {
  u <- par("usr")
  x0 <- u[1] + pos[1] * (u[2] - u[1])
  y0 <- u[3] + pos[2] * (u[4] - u[3])
  segments(x0, y0, x0 + km * unit, y0, lwd = lwd, lend = 1)
  text(x0 + km * unit / 2, y0, paste(km, "km"), pos = 3, cex = cex)
}

# Buffalo, Kruger NP: drop missing, (0, 0) and duplicated fixes (Session 3,
# Task 1). Returns longitude/latitude (lon, lat) and UTM 36S metres (x, y).
read_buffalo <- function() {
  d <- read.csv("data/buffalo_kruger.csv.gz")
  d <- data.frame(id  = d$individual.local.identifier,
                  t   = as.POSIXct(d$timestamp, tz = "UTC"),
                  lon = d$location.long, lat = d$location.lat)
  d <- d[!is.na(d$lon) & !is.na(d$lat) & !(d$lon == 0 & d$lat == 0), ]
  d <- d[!duplicated(d[, c("id", "t")]), ]
  d <- d[order(d$id, d$t), ]
  xy <- sf::sf_project("EPSG:4326", "EPSG:32736", cbind(d$lon, d$lat))
  d$x <- xy[, 1]; d$y <- xy[, 2]
  rownames(d) <- NULL
  d
}

# Leo the vulture: longitude/latitude, and a global equal-area projection
# (EPSG:6933) because no UTM zone covers 47 degrees of latitude.
read_leo <- function() {
  d <- read.csv("data/vulture_leo.csv.gz")
  d <- data.frame(t = as.POSIXct(d$timestamp, tz = "UTC"),
                  lon = d$location.long, lat = d$location.lat)
  d <- d[!is.na(d$lon) & !is.na(d$lat), ]
  d <- d[!duplicated(d$t), ]
  d <- d[order(d$t), ]
  xy <- sf::sf_project("EPSG:4326", "EPSG:6933", cbind(d$lon, d$lat))
  d$x <- xy[, 1]; d$y <- xy[, 2]
  rownames(d) <- NULL
  d
}
