// Forwards the qmd YAML options to the `poster()` function.
#show: doc => poster(
$if(title)$  title: [$title$], $endif$
$if(subtitle)$  subtitle: [$subtitle$], $endif$
$if(poster-authors)$  authors: [$poster-authors$], $endif$
$if(affiliations-line)$  affiliations: [$affiliations-line$], $endif$
$if(badge)$  badge: [$badge$], $endif$
$if(header-image)$  header-image: "$header-image$", $endif$
$if(size)$  size: "$size$", $endif$
$if(num-columns)$  num-columns: $num-columns$, $endif$
$if(base-font-size)$  font-size: $base-font-size$, $endif$
  doc,
)
