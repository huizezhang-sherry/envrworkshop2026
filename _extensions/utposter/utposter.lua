-- Maps poster divs/spans in the qmd to Typst components in typst-template.typ
--   ::: {.card accent="orange"}   -> #card(accent: "orange")[ ... ]
--   ::: {.card fill-height=true}  -> card that stretches to the column bottom
--                                    (applied automatically to the last card in
--                                    every column so all columns end level;
--                                    opt out with fill-height=false)
--   ::: {.takeaway}               -> #takeaway[ ... ]
--   ::: {.caption}                -> #caption[ ... ]
--   ::: {.two-up}                 -> #two-up([child 1], [child 2])
--   ::: {.side-by-side}           -> #side-by-side([child 1], [child 2])  (no box)
--   ::: {.colbreak}               -> #colbreak()
--   [2012]{.yr}                   -> #pill[2012]
--   [text]{.cite}                 -> #muted[text]
--   a paragraph holding only an image is centred in the card

if not quarto.doc.is_format("typst") then
  return {}
end

local function raw(s) return pandoc.RawBlock("typst", s) end
local function rawi(s) return pandoc.RawInline("typst", s) end

local function wrap(open, blocks)
  local out = { raw(open) }
  for _, b in ipairs(blocks) do table.insert(out, b) end
  table.insert(out, raw("]"))
  return out
end

local function Div(el)
  local c = el.classes
  if c:includes("colbreak") then
    return raw("#colbreak()")
  elseif c:includes("card") then
    local args = {}
    if el.attributes["accent"] then
      table.insert(args, 'accent: "' .. el.attributes["accent"] .. '"')
    end
    if el.attributes["fill-height"] == "true" or el.attributes["auto-fill"] == "true" then
      table.insert(args, "fill-height: true")
    end
    return wrap("#card(" .. table.concat(args, ", ") .. ")[", el.content)
  elseif c:includes("takeaway") then
    return wrap("#takeaway[", el.content)
  elseif c:includes("caption") then
    return wrap("#caption[", el.content)
  elseif c:includes("two-up") or c:includes("side-by-side") then
    local fn = c:includes("two-up") and "two-up" or "side-by-side"
    local out = { raw("#" .. fn .. "(") }
    for _, child in ipairs(el.content) do
      if child.t == "Div" then
        table.insert(out, raw("["))
        for _, b in ipairs(child.content) do table.insert(out, b) end
        table.insert(out, raw("],"))
      end
    end
    table.insert(out, raw(")"))
    return out
  end
end

-- Pandoc writes standalone images as inline boxes, so centre them here
local function Para(el)
  if #el.content == 1 and el.content[1].t == "Image" then
    return { raw("#align(center)["), el, raw("]") }
  end
end

local function Span(el)
  local c = el.classes
  if c:includes("yr") then
    local out = { rawi("#pill[") }
    for _, i in ipairs(el.content) do table.insert(out, i) end
    table.insert(out, rawi("]"))
    return out
  elseif c:includes("cite") then
    local out = { rawi("#muted[") }
    for _, i in ipairs(el.content) do table.insert(out, i) end
    table.insert(out, rawi("]"))
    return out
  end
end

-- First pass: mark the last card before each column break (and at the end)
-- so every column's final card stretches to the bottom of the page.
local function align_columns(doc)
  local last_card = nil
  local function close_column()
    if last_card and last_card.attributes["fill-height"] ~= "false" then
      last_card.attributes["auto-fill"] = "true"
    end
    last_card = nil
  end
  for _, b in ipairs(doc.blocks) do
    if b.t == "Div" and b.classes:includes("colbreak") then
      close_column()
    elseif b.t == "Div" and b.classes:includes("card") then
      last_card = b
    end
  end
  close_column()
  return doc
end

return {
  { Pandoc = align_columns },
  { Div = Div, Span = Span, Para = Para },
}
