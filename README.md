# Glyph maps poster — envr workshop 2026

A 48 × 36 in poster introducing glyph maps in R with **GGally**, **cubble**
and **sugarglider**.

## Render

```bash
quarto render        # writes poster.pdf directly (Typst)
```

## Layout

| Path | What it is |
|---|---|
| `poster.qmd` | The poster: text and the R code for every figure |
| `_extensions/utposter/` | Custom Quarto Typst format: UT Austin colours, header, card layout (`typst-template.typ`), div → Typst mapping (`utposter.lua`), bundled fonts |
| `data/get-sydney.R` | Downloads the TidyTuesday Sydney beaches data and builds `data/sydney-recovery.csv` (run once; rendering does not need the internet) |
| `data/sydney-recovery.csv` | Per site: share of samples above 40 enterococci/100 mL, 0–7 days after ≥ 20 mm of rain |
| `figures/header-glyph.png` | Header decoration, regenerated on each render |

## Data

- NASA surface temperature: `GGally::nasa`
- Sydney beach water quality: NSW Beachwatch, via
  [TidyTuesday 2025-05-20](https://github.com/rfordatascience/tidytuesday/tree/main/data/2025/2025-05-20)
- Australian temperature: `sugarglider::aus_temp`

## Markup available in `poster.qmd`

- `::: {.card accent="orange"}` — a card (`accent`: `orange`, `blue`, or omit for charcoal)
- `::: {.colbreak}` + `:::` — start the next column
- `::: {.takeaway}`, `::: {.caption}`, `::: {.two-up}`, `::: {.side-by-side}`
- `[2012]{.yr}` — year pill, `[text]{.cite}` — grey citation
- The last card in each column stretches to the bottom automatically
