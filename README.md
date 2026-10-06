# Seeing space and time together: glyph maps in R

Poster for the ENVR Workshop 2026 (Houston, Texas): line, interval and
interactive glyph maps in ggplot2 with **cubble** and **sugarglider**.
48 × 36 in, landscape.

## Render

```bash
quarto render        # writes poster.pdf directly (Typst)
```

Requires R with ggplot2, dplyr, patchwork, sf, ozmaps, rnaturalearth, cubble,
sugarglider, GGally and qrcode. Rendering does not need the internet: the
Sydney data and the leaflet screenshot are cached in the repository.

## Files

| Path | What it is |
|---|---|
| `poster.qmd` | The poster: text and the R code for every figure |
| `scripts/poster-examples.R` | Standalone code for the three examples: (1) Sydney beaches with cubble, (2) Australian temperature segments, (3) Melbourne train ribbons on leaflet. Re-creates `data/sydney-recovery.csv` and `figures/leaflet-train.html` |
| `data/sydney-recovery.csv` | Per swim site: share of samples above 40 enterococci/100 mL, 0–7 days after ≥ 20 mm of rain |
| `figures/leaflet-train.html` | Interactive leaflet glyph map of Melbourne train stations |
| `figures/leaflet-train.png` | Screenshot of the leaflet map used on the poster (command at the end of the script) |
| `figures/header-logos.png` | cubble and sugarglider hex logos (from `*-logo.svg`, taken from the package repositories) |
| `_extensions/utposter/` | Custom Quarto Typst format: UT Austin colours, header, card layout (`typst-template.typ`), div → Typst mapping (`utposter.lua`), bundled fonts |

## Data

- NASA surface temperature, Central America: `GGally::nasa`
- Sydney beach water quality: NSW Beachwatch, via
  [TidyTuesday 2025-05-20](https://github.com/rfordatascience/tidytuesday/tree/main/data/2025/2025-05-20)
- Australian temperature: `sugarglider::aus_temp`
- Melbourne train patronage: `sugarglider::train`; leaflet tiles © Esri

## Markup available in `poster.qmd`

- `::: {.card accent="orange"}` — a card (`accent`: `orange`, `blue`, or omit for charcoal)
- `::: {.colbreak}` + `:::` — start the next column
- `::: {.takeaway}`, `::: {.caption}`, `::: {.two-up}`, `::: {.side-by-side}`
- `[2012]{.yr}` — year pill, `[text]{.cite}` — grey citation
- The last card in each column stretches to the bottom automatically

Contact: H. Sherry Zhang, hsherryzhang@utexas.edu
