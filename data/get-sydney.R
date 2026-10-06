# Sydney beach water quality (NSW Beachwatch, via TidyTuesday 2025-05-20).
# For each swim site: share of samples above 40 enterococci/100 mL
# (NHMRC guideline) by days since the last day with >= 20 mm of rain.
# Run once; the poster reads the cached data/sydney-recovery.csv.
library(dplyr)
base <- "https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2025/2025-05-20/"
wq <- readr::read_csv(paste0(base, "water_quality.csv"), show_col_types = FALSE)
wx <- readr::read_csv(paste0(base, "weather.csv"), show_col_types = FALSE) |> arrange(date)
# days since the last heavy-rain day (>= 20 mm)
last <- as.Date(NA); since <- integer(nrow(wx))
for (i in seq_len(nrow(wx))) {
  if (!is.na(wx$precipitation_mm[i]) && wx$precipitation_mm[i] >= 20) last <- wx$date[i]
  since[i] <- as.integer(wx$date[i] - last)
}
wx$since <- since
rec <- wq |>
  filter(!is.na(enterococci_cfu_100ml), region != "Western Sydney") |>
  left_join(select(wx, date, since), by = "date") |>
  filter(!is.na(since), since <= 7) |>
  group_by(swim_site, region) |>
  mutate(long = median(longitude), lat = median(latitude)) |>
  group_by(swim_site, region, long, lat, since) |>
  summarise(unsafe = mean(enterococci_cfu_100ml > 40), n = n(), .groups = "drop")
readr::write_csv(rec, "data/sydney-recovery.csv")
message(n_distinct(rec$swim_site), " sites saved")
