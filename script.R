# Glyph map examples from the poster
#   1. Sydney beaches: how long after a storm is it safe to swim? (cubble)
#   2. Australian temperature: daily low-high by month          (sugarglider segments)
#   3. Melbourne trains: hourly passengers on leaflet           (sugarglider ribbons)
#
# Run from the project root. Each section is self-contained.

library(dplyr)
library(ggplot2)
library(grid) # sugarglider::add_glyph_legend() needs grid attached
library(cubble)
library(sugarglider)
library(lubridate)

# =============================================================================
# 1. Sydney beaches (cubble::geom_glyph)
# =============================================================================
# Data: NSW Beachwatch water quality + Sydney rainfall, TidyTuesday 2025-05-20.
# For each swim site: share of samples above 40 enterococci / 100 mL (the
# NHMRC guideline) on days 0-6 after a day with >= 20 mm of rain.

## ---- beach-data ----
tuesdata <- tidytuesdayR::tt_load("2025-05-20")
water <- tuesdata$water_quality |> arrange(date) |> filter(year(date) >= 2015)
weather <- tuesdata$weather |> arrange(date) |> filter(year(date) >= 2015)

# days since the last heavy-rain day
weather <- weather |>
  mutate(last_rain = if_else(precipitation_mm >= 20, date, as.Date(NA))) |>
  tidyr::fill(last_rain) |>
  mutate(days_after_rain = as.integer(date - last_rain)) |>
  select(-last_rain)

beach <- water |>
  filter(!is.na(enterococci_cfu_100ml), region != "Western Sydney") |>
  left_join(select(weather, date, days_after_rain), by = "date") |>
  filter(!is.na(days_after_rain), days_after_rain <= 6) |>
  group_by(
    swim_site, region, long = longitude, lat = latitude, days_after_rain
  ) |>
  summarise(
    unsafe = mean(enterococci_cfu_100ml > 40), n = n(),
    .groups = "drop"
  )

# central Sydney; harbour sites >= 7 km from the Heads count as inner harbour
beach <- beach |>
  filter(lat > -33.99, lat < -33.74, long > 151.1) |>
  group_by(swim_site) |>
  ungroup() |>
  mutate(
    # straight-line km from the harbour entrance (between North and South Head)
    km_heads = sqrt(((long - 151.287) * 92.6)^2 + ((lat + 33.834) * 111)^2),
    water = ifelse(
      region == "Sydney Harbour" & km_heads >= 7,
      "Inner harbour", "Ocean & outer harbour"
    )
  )

## ---- beach-select ----
# keep sites whose glyph boxes do not overlap; inner harbour sites first,
# then best-sampled sites
gw <- 0.028
gh <- 0.012 # glyph size (degrees)
sites <- beach |>
  group_by(swim_site, water, long, lat) |>
  summarise(n = sum(n), .groups = "drop") |>
  arrange(desc(water == "Inner harbour"), desc(n))
keep <- integer(0)
for (i in seq_len(nrow(sites))) {
  clear <- abs(sites$long[i] - sites$long[keep]) > gw |
    abs(sites$lat[i] - sites$lat[keep]) > gh * 1.05
  if (all(clear)) keep <- c(keep, i)
}
beach <- beach |> filter(swim_site %in% sites$swim_site[keep])

# council boundaries give a coastline that includes Sydney Harbour
sf::sf_use_s2(FALSE)
sydney <- ozmaps::abs_lga |>
  sf::st_union() |>
  sf::st_crop(xmin = 151.0, xmax = 151.4, ymin = -34.1, ymax = -33.65)

## ---- beach-plot ----
p_beach <- ggplot(beach, aes(
  x_major = long, y_major = lat,
  x_minor = days_after_rain, y_minor = unsafe,
  colour = water, group = swim_site
)) +
  geom_sf(data = sydney, fill = "#EAE6DF", colour = NA, inherit.aes = FALSE) +
  geom_glyph_box(width = gw, height = gh, colour = "grey80", linewidth = 0.2, alpha = 0.05) +
  geom_glyph(width = gw, height = gh, linewidth = 0.6) +
  geom_text(data = beach |> distinct(swim_site, long, lat), 
            aes(x = long, y = lat - 0.008, label = swim_site),  inherit.aes = FALSE) + 
  scale_colour_manual(
    values = c(
      `Inner harbour` = "#BF5700", `Ocean & outer harbour` = "#005F86"
    ),
    name = NULL
  ) +
  coord_sf(xlim = c(151.10, 151.33), ylim = c(-34.0, -33.73)) +
  theme_void() +
  theme(legend.position = "bottom", panel.background = element_rect(fill = "#e8f3ff"))
p_beach
# ggsave("sydney-beaches.png", p_beach, width = 6, height = 6)
#
## ---- aus-temp ----
# =============================================================================
# 2. Australian temperature (sugarglider::geom_glyph_segment)
# =============================================================================
# Data: sugarglider::aus_temp, monthly average daily min / max temperature at
# 29 Australian weather stations, 2020 (stored in tenths of a degree).

aus <- aus_temp |> mutate(across(c(tmin, tmax), \(x) x / 10))

p_aus <- ggplot(aus, aes(
  x_major = long, y_major = lat,
  x_minor = month,
  y_minor = tmin, yend_minor = tmax
)) +
  geom_sf(
    data = ozmaps::abs_ste, fill = "grey92", colour = "white",
    inherit.aes = FALSE
  ) +
  add_glyph_boxes(width = 3.4, height = 2.2, colour = "grey60") +
  add_ref_lines(width = 3.4, height = 2.2, colour = "grey60") +
  geom_glyph_segment(
    width = 3.4, height = 2.2, colour = "#BF5700",
    linewidth = 0.6
  ) +
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
# Stations shown: the City Loop and the inner stations around it, west to
# Footscray, north-east to Victoria Park, south-east to Prahran and Burnley.
city_loop <- c(
  "Flinders Street", "Southern Cross", "Flagstaff", "Melbourne Central",
  "Parliament"
)
show <- c(
  city_loop,
  "Footscray", "South Kensington", "Macaulay", "North Melbourne", # west
  "Jolimont", "North Richmond", "Victoria Park", # north-east
  "Richmond", "South Yarra", "Prahran", # south
  "Burnley" # east
)
poster_stations <- c("Melbourne Central", "South Yarra") # enlarged on poster
stations <- train_hr |>
  distinct(station_name, long, lat) |>
  filter(station_name %in% show)

zoom <- 13 # 1 km scale bar
icon_w <- 60
icon_h <- 40 # icon size (px)

# Nudge crowded inner-city glyphs so they don't overlap (in screen px at
# this zoom; + is right / up). Only the drawing position moves.
nudge <- tibble::tribble(
  ~station_name, ~dx, ~dy,
  "Melbourne Central", 0, 30,
  "Flagstaff", -62, -6,
  "Southern Cross", -20, -30,
  "Flinders Street", 18, -10,
  "Parliament", 6, -8,
  "Jolimont", 24, -10,
  "Richmond", 0, -14,
  "North Melbourne", -14, 14
)
px_deg <- 360 / (256 * 2^zoom) # degrees longitude per pixel
stations <- stations |>
  left_join(nudge, by = "station_name") |>
  mutate(
    long = long + coalesce(dx, 0) * px_deg,
    lat = lat + coalesce(dy, 0) * px_deg * cos(lat * pi / 180)
  ) |>
  select(-dx, -dy)

# Each station on its own scale: the ribbon fills the glyph box, so glyphs
# compare the daily *shape* (commuter peaks vs all-day), not how busy a
# station is. Hour and passengers are rescaled to [-1, 1] within each station.
local <- train_hr |>
  group_by(station_name) |>
  mutate(
    x = scales::rescale(hour, to = c(-1, 1)),
    ymin = scales::rescale(min_weekday, to = c(-1, 1),
                           from = range(min_weekday, max_weekday)),
    ymax = scales::rescale(max_weekday, to = c(-1, 1),
                           from = range(min_weekday, max_weekday))
  ) |>
  ungroup()

make_icon <- function(s, border = "#9CADB7", lw = 2) {
  p <- local |>
    filter(station_name == s) |>
    ggplot(aes(x, ymin = ymin, ymax = ymax)) +
    annotate("rect",
      xmin = -1, xmax = 1, ymin = -1, ymax = 1,
      fill = "white", alpha = 0.35, colour = border, linewidth = lw
    ) +
    geom_ribbon(fill = "#005F86", alpha = 0.55, colour = "#005F86", linewidth = 0.4) +
    coord_cartesian(xlim = c(-1, 1), ylim = c(-1, 1), expand = FALSE) +
    theme_void()
  f <- tempfile(fileext = ".png")
  ggsave(f, p, width = 3, height = 1.5, dpi = 100, bg = "transparent")
  knitr::image_uri(f) # embed the image in the html
}
icon_uri <- vapply(stations$station_name, make_icon, character(1))

m <- leaflet(options = leafletOptions(zoomControl = FALSE)) |> # no +/- buttons
  addProviderTiles("Esri.WorldGrayCanvas") |>
  # inner city at a 1 km scale (view nudged south: a row of tiles north of it is missing)
  setView(lng = 144.9554, lat = -37.8243, zoom = zoom) |>
  addScaleBar(position = "bottomleft") |>
  addMarkers(
    lng = stations$long, lat = stations$lat,
    label = stations$station_name,
    # station name always shown, just under the icon
    labelOptions = labelOptions(
      noHide = TRUE, textOnly = TRUE, direction = "bottom",
      offset = c(0, icon_h / 2 - 10),
      style = list(
        "font-size" = "16px", "font-weight" = "bold", "color" = "#333F48",
        "text-shadow" = "0 0 2px white, 0 0 2px white, 0 0 2px white"
      )
    ),
    icon = icons(
      iconUrl = unname(icon_uri),
      iconWidth = icon_w, iconHeight = icon_h
    )
  )

# the two stations enlarged on the poster: dark border (as on the other maps), drawn on top
hl <- stations |> filter(station_name %in% poster_stations)
hl_icons <- vapply(hl$station_name, make_icon, character(1),
  border = "#333F48", lw = 8
)
m <- m |> addMarkers(
  lng = hl$long, lat = hl$lat,
  icon = icons(
    iconUrl = unname(hl_icons),
    iconWidth = icon_w, iconHeight = icon_h
  ),
  options = markerOptions(zIndexOffset = 1000)
)
m

htmlwidgets::saveWidget(m, file.path(normalizePath("figures"), "leaflet-train.html"),
  selfcontained = TRUE
)
# Screenshot used on the poster (macOS, headless Chrome):
#   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless \
#     --hide-scrollbars --force-device-scale-factor=2 --virtual-time-budget=15000 --window-size=690,488 \
#     --screenshot=figures/leaflet-train.png file://$PWD/figures/leaflet-train.html
