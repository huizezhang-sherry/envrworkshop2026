# Glyph map examples from the poster
#   1. Sydney beaches: how long after a storm is it safe to swim? (cubble)
#   2. Australian temperature: daily low-high by month          (sugarglider segments)
#   3. Melbourne trains: hourly passengers on leaflet           (sugarglider ribbons)
#
# Run from the project root. Each section is self-contained.

library(dplyr)
library(ggplot2)
library(grid)            # sugarglider::add_glyph_legend() needs grid attached
library(cubble)
library(sugarglider)

# =============================================================================
# 1. Sydney beaches (cubble::geom_glyph)
# =============================================================================
# Data: NSW Beachwatch water quality + Sydney rainfall, TidyTuesday 2025-05-20.
# For each swim site: share of samples above 40 enterococci / 100 mL (the
# NHMRC guideline) on each of the 7 days after a day with >= 20 mm of rain.

tt <- "https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-05-20/"
water   <- readr::read_csv(paste0(tt, "water_quality.csv"), show_col_types = FALSE)
weather <- readr::read_csv(paste0(tt, "weather.csv"), show_col_types = FALSE) |>
  arrange(date)

# days since the last heavy-rain day
last <- as.Date(NA)
weather$days_after_rain <- NA_integer_
for (i in seq_len(nrow(weather))) {
  if (!is.na(weather$precipitation_mm[i]) && weather$precipitation_mm[i] >= 20)
    last <- weather$date[i]
  weather$days_after_rain[i] <- as.integer(weather$date[i] - last)
}

beach <- water |>
  filter(!is.na(enterococci_cfu_100ml), region != "Western Sydney") |>
  left_join(select(weather, date, days_after_rain), by = "date") |>
  filter(!is.na(days_after_rain), days_after_rain <= 7) |>
  group_by(swim_site, region) |>
  mutate(long = median(longitude), lat = median(latitude)) |>
  group_by(swim_site, region, long, lat, days_after_rain) |>
  summarise(unsafe = mean(enterococci_cfu_100ml > 40), n = n(),
            .groups = "drop")
readr::write_csv(beach, "data/sydney-recovery.csv")   # cached for the poster

# central Sydney; keep sites whose glyph boxes do not overlap
gw <- 0.028; gh <- 0.012                              # glyph size (degrees)
beach <- beach |>
  filter(lat > -33.99, lat < -33.74, long > 151.1) |>
  group_by(swim_site) |> filter(sum(n) >= 80) |> ungroup()
sites <- beach |>
  group_by(swim_site, long, lat) |>
  summarise(n = sum(n), .groups = "drop") |> arrange(desc(n))
keep <- integer(0)
for (i in seq_len(nrow(sites))) {
  clear <- abs(sites$long[i] - sites$long[keep]) > gw |
           abs(sites$lat[i]  - sites$lat[keep])  > gh * 1.05
  if (all(clear)) keep <- c(keep, i)
}
beach <- beach |>
  filter(swim_site %in% sites$swim_site[keep]) |>
  mutate(water = ifelse(region == "Sydney Harbour", "Harbour", "Ocean beach"))

# council boundaries give a coastline that includes Sydney Harbour
sf::sf_use_s2(FALSE)
sydney <- ozmaps::abs_lga |> sf::st_union() |>
  sf::st_crop(xmin = 151.0, xmax = 151.4, ymin = -34.1, ymax = -33.65)

p_beach <- ggplot(beach, aes(x_major = long, y_major = lat,
                             x_minor = days_after_rain, y_minor = unsafe,
                             colour = water, group = swim_site)) +
  geom_sf(data = sydney, fill = "grey92", colour = NA, inherit.aes = FALSE) +
  geom_glyph_box(width = gw, height = gh, colour = "grey60", linewidth = 0.2) +
  geom_glyph(width = gw, height = gh, linewidth = 0.6) +
  scale_colour_manual(values = c(Harbour = "#BF5700", `Ocean beach` = "#005F86"),
                      name = NULL) +
  coord_sf(xlim = c(151.10, 151.33), ylim = c(-34.0, -33.73)) +
  theme_void() +
  theme(legend.position = "bottom")
p_beach
# ggsave("sydney-beaches.png", p_beach, width = 6, height = 6)

# =============================================================================
# 2. Australian temperature (sugarglider::geom_glyph_segment)
# =============================================================================
# Data: sugarglider::aus_temp, monthly average daily min / max temperature at
# 29 Australian weather stations, 2020 (stored in tenths of a degree).

aus <- aus_temp |> mutate(across(c(tmin, tmax), \(x) x / 10))

p_aus <- ggplot(aus, aes(x_major = long, y_major = lat,
                         x_minor = month,
                         y_minor = tmin, yend_minor = tmax)) +
  geom_sf(data = ozmaps::abs_ste, fill = "grey92", colour = "white",
          inherit.aes = FALSE) +
  add_glyph_boxes(width = 3.4, height = 2.2, colour = "grey60") +
  add_ref_lines(width = 3.4, height = 2.2, colour = "grey60") +
  geom_glyph_segment(width = 3.4, height = 2.2, colour = "#BF5700",
                     linewidth = 0.6) +
  coord_sf(xlim = c(111.5, 155.5), ylim = c(-44.5, -8.8)) +
  theme_glyph()
p_aus
# ggsave("australia-temperature.png", p_aus, width = 6, height = 5)

# =============================================================================
# 3. Melbourne trains on leaflet (sugarglider::geom_glyph_ribbon)
# =============================================================================
# Data: sugarglider::train, hourly weekday patronage at Victorian train
# stations, 2023-24. For each hour the ribbon spans the quietest to the
# busiest month. Each station's glyph is saved as an image and added as a
# leaflet marker (the approach in the sugarglider paper).

library(leaflet)

train_hr <- train |>
  mutate(hour = as.numeric(substr(as.character(hour), 1, 2)))
stations <- train_hr |>
  distinct(station_name, long, lat) |>
  filter(long > 144.80, long < 145.15, lat > -37.95, lat < -37.70)

# One shared scale for all stations: let sugarglider rescale every station
# together (global_rescale = TRUE, all glyphs placed at the same spot), then
# draw each station's rescaled ribbon as its own icon.
shared <- layer_data(
  ggplot(train_hr, aes(x_major = 0, y_major = 0, x_minor = hour,
                       ymin_minor = min_weekday, ymax_minor = max_weekday,
                       group = station_name)) +
    geom_glyph_ribbon(width = 2, height = 2, global_rescale = TRUE)) |>
  mutate(station_name = levels(factor(train_hr$station_name))[group])

make_icon <- function(s, border = "#9CADB7", lw = 1) {
  p <- shared |>
    filter(station_name == s) |>
    ggplot(aes(x, ymin = ymin, ymax = ymax)) +
    annotate("rect", xmin = -1, xmax = 1, ymin = -1, ymax = 1,
             fill = "white", alpha = 0.85, colour = border, linewidth = lw) +
    geom_ribbon(fill = "#005F86", colour = "#005F86", alpha = 0.85) +
    coord_cartesian(xlim = c(-1, 1), ylim = c(-1, 1), expand = FALSE) +
    theme_void()
  f <- tempfile(fileext = ".png")
  ggsave(f, p, width = 3, height = 2, dpi = 100, bg = "transparent")
  knitr::image_uri(f)                      # embed the image in the html
}
icon_uri <- vapply(stations$station_name, make_icon, character(1))

m <- leaflet() |>
  addProviderTiles("Esri.WorldGrayCanvas") |>
  setView(lng = 144.985, lat = -37.827, zoom = 13) |>
  addScaleBar(position = "bottomleft") |>
  addMarkers(lng = stations$long, lat = stations$lat,
             label = stations$station_name,
             icon = icons(iconUrl = unname(icon_uri),
                          iconWidth = 66, iconHeight = 44))

# the two stations enlarged on the poster: orange border, drawn on top
hl <- stations |> filter(station_name %in% c("Melbourne Central", "South Yarra"))
hl_icons <- vapply(hl$station_name, make_icon, character(1),
                   border = "#BF5700", lw = 4)
m <- m |> addMarkers(lng = hl$long, lat = hl$lat, label = hl$station_name,
                     icon = icons(iconUrl = unname(hl_icons),
                                  iconWidth = 66, iconHeight = 44),
                     options = markerOptions(zIndexOffset = 1000))
m

htmlwidgets::saveWidget(m, file.path(normalizePath("figures"), "leaflet-train.html"),
                        selfcontained = TRUE)
# Screenshot used on the poster (macOS, headless Chrome):
#   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless \
#     --hide-scrollbars --force-device-scale-factor=2 --virtual-time-budget=15000 --window-size=860,470 \
#     --screenshot=figures/leaflet-train.png file://$PWD/figures/leaflet-train.html
