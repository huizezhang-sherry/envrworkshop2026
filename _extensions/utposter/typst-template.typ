// UT Austin poster template for Quarto + Typst.
// Layout: full-width header band, then N columns of cards.
// Column breaks are explicit (`::: {.colbreak}` in the qmd).

// ---- UT Austin brand colours -------------------------------------------
#let ut-orange   = rgb("#BF5700")   // burnt orange
#let ut-charcoal = rgb("#333F48")
#let ut-blue     = rgb("#005F86")   // secondary
#let ut-yellow   = rgb("#FFD600")   // secondary (sunshine)
#let ut-shade    = rgb("#9CADB7")
#let ut-paper    = rgb("#F3F1EC")   // light limestone
#let ut-muted    = rgb("#5d6b75")
#let ut-tint     = rgb("#fbeadc")   // light burnt orange

#let accent-colour(name) = {
  if name == "orange" { ut-orange }
  else if name == "blue" { ut-blue }
  else { ut-charcoal }
}

// ---- components used by the Lua filter ---------------------------------
#let card(accent: "charcoal", fill-height: false, body) = block(
  width: 100%,
  height: if fill-height { 1fr } else { auto },
  breakable: false,
  fill: white,
  radius: 14pt,
  stroke: (top: 9pt + accent-colour(accent)),
  inset: (x: 26pt, top: 24pt, bottom: 20pt),
  below: 30pt,
  body,
)

#let takeaway(body) = block(
  width: 100%,
  fill: ut-tint,
  stroke: (left: 7pt + ut-orange),
  radius: (right: 6pt),
  inset: (x: 16pt, y: 10pt),
  above: 6pt,
  below: 10pt,
  text(size: 0.92em, body),
)

#let caption(body) = align(center, text(size: 0.85em, fill: ut-muted, body))

#let pill(body) = box(
  fill: ut-orange,
  inset: (x: 8pt, y: 4pt),
  outset: (y: 2pt),
  radius: 5pt,
  text(fill: white, weight: 700, size: 0.85em, body),
)

#let muted(body) = text(fill: ut-muted, body)

#let two-up(..cells) = grid(
  columns: (1fr, 1fr),
  column-gutter: 14pt,
  ..cells.pos().map(c => block(
    width: 100%, fill: ut-tint, radius: 8pt, inset: 12pt, text(size: 0.92em, c),
  )),
)

#let side-by-side(..cells) = grid(
  columns: (1fr, 1fr),
  column-gutter: 14pt,
  align: horizon,
  ..cells.pos(),
)

// ---- the poster ---------------------------------------------------------
#let poster(
  title: none,
  subtitle: none,
  authors: none,
  affiliations: none,
  badge: none,
  header-image: none,
  size: "48x36",
  num-columns: 4,
  header-height: 5.2in,
  margin: 0.55in,
  gutter: 0.55in,
  font-size: 28pt,
  body,
) = {
  let dims = size.split("x")
  let width = float(dims.at(0)) * 1in
  let height = float(dims.at(1)) * 1in

  set document(title: title)
  set text(font: "Source Sans 3", size: font-size, fill: ut-charcoal)
  set par(justify: false, leading: 0.5em, spacing: 0.75em)

  // header band (drawn as page background so it bleeds to the edges)
  let header = {
    place(top + left, rect(
      width: 100%, height: header-height,
      fill: gradient.linear(ut-orange, rgb("#a94d00"), ut-charcoal, angle: 15deg),
    ))
    place(top + left, dy: header-height,
      rect(width: 100%, height: 0.16in, fill: ut-charcoal))
    place(top + left, dx: margin, dy: 0.75in, block(width: width - 2 * margin - 10in, {
      set text(fill: white)
      text(size: 92pt, weight: 900, tracking: -1pt, title)
      if subtitle != none {
        v(8pt)
        text(size: 40pt, fill: rgb("#fff3e8"), subtitle)
      }
      v(4pt)
      if authors != none { text(size: 32pt, authors) }
      v(-2pt)
      if affiliations != none { text(size: 22pt, fill: rgb("#fde3cf"), affiliations) }
      if badge != none {
        h(20pt)
        box(fill: ut-yellow, inset: (x: 12pt, y: 5pt), outset: (y: 3pt), radius: 6pt,
          text(size: 22pt, weight: 700, fill: ut-charcoal, badge))
      }
    }))
    if header-image != none {
      place(top + right, dx: -margin, dy: 0.3in,
        image(header-image, height: header-height - 0.6in))
    }
  }

  set page(
    width: width,
    height: height,
    fill: ut-paper,
    margin: (top: header-height + 0.16in + margin, rest: margin),
    background: header,
  )

  // headings: card titles (Quarto shifts `##` to level 1 for Typst)
  show heading: it => block(below: 28pt, above: 0pt,
    text(size: 46pt, weight: 700, fill: ut-charcoal, it.body))
  set heading(numbering: none)

  // code
  show raw: set text(font: "Fira Code")
  show raw.where(block: true): it => block(
    width: 100%, fill: rgb("#f4f2ee"), radius: 8pt, inset: 12pt,
    text(size: 20pt, it))
  show raw.where(block: false): it => box(
    fill: rgb("#eef1f3"), inset: (x: 4pt, y: 2pt), outset: (y: 2pt), radius: 4pt,
    text(size: 0.95em, fill: ut-blue, it))

  // links, lists, tables, images
  show link: it => text(fill: ut-blue, underline(it))
  set list(indent: 6pt, body-indent: 10pt, spacing: 0.6em)
  set enum(indent: 6pt, body-indent: 10pt, spacing: 0.6em)
  set table(
    stroke: (x, y) => (bottom: if y == 0 { 2pt + ut-charcoal } else { 1pt + rgb("#dde3ea") }),
    fill: (x, y) => if y > 0 and calc.odd(y) { rgb("#f7f9fb") },
    inset: (x: 6pt, y: 6pt),
    align: (x, y) => if x == 0 { left } else { center },
  )
  show table: set text(size: 22pt)
  show table.cell.where(y: 0): set text(weight: 700)
  show image: it => align(center, it)
  show figure: set block(above: 6pt, below: 10pt)

  columns(num-columns, gutter: gutter, body)
}
