#import "@preview/cetz:0.5.2"

#let accent       = rgb("#4f46e5") // Vibrant indigo-purple; high energy, crisp on white
#let accent-light = rgb("#eef2ff") // Pale indigo wash for callouts and badges
#let ink          = rgb("#0f172a") // Slate-black with high text contrast
#let muted        = rgb("#475569") // Slate-gray for secondary text and dates
#let rule-color   = rgb("#e0e7ff") // Indigo-tinted hairline rule
#let code-bg      = rgb("#f8fafc") // Clean, cool background



#let font-body = ("TeX Gyre Pagella")
#let font-sans = ("New Computer Modern Sans")
#let font-mono = ("JetBrains Mono")


#let title-block(title, subtitle, authors, group, course, version, date) = {
  v(-1em)
  {
    set text(font: font-sans)

    grid(
      columns: (1fr, auto),
      align: (horizon, bottom),
      block({
        set text(2.6em, weight: 700)
        title
      }) + {
        set par(justify: false)
        set text(1.2em, weight: "bold")
        subtitle
      },
      {
        set align(left)
        text(1.2em)[*Group #group*]
        linebreak()
        [#authors.first().name (#authors.first().id)]
        linebreak()
        [#authors.last().name (#authors.last().id)]
      }
    )
  }
  line(length: 100%, stroke: 0.6pt + rule-color)
  v(1.2em)
}

#let doc(
  title: "MiniRISC",
  subtitle: none,
  authors: (),
  group: "—",
  course: none,
  version: "v0.1",
  date: datetime.today(),
  body,
) = {
  set document(
    title: title + " – " + subtitle,
    author: authors.map(a => if type(a) == dictionary { a.name } else { a }),
  )
  set text(font: font-body, size: 10pt, fill: ink, lang: "en")
  set par(justify: true, leading: 0.66em, spacing: 1em)

  set page(
    paper: "a4",
    margin: (x: 2.5cm, top: 2.3cm, bottom: 2.4cm),
    header: context {
      if here().page() > 1 {
        set text(font: font-sans, size: 8.5pt, fill: muted)
        grid(columns: (1fr, 1fr), [#title], align(right)[#subtitle])
        v(-4pt)
        line(length: 100%, stroke: 0.5pt + rule-color)
      }
    },
    footer: context {
      set text(font: font-sans, size: 8.5pt, fill: muted)
      align(center, counter(page).display())
    },
  )

  set heading(numbering: "1.1.1")
  show heading: set text(font: font-sans, fill: ink)
  show heading.where(level: 1): it => {
    v(1.3em, weak: true)
    block(below: 0.8em, sticky: true, {
      text(size: 17pt, weight: "bold", fill: accent, [#counter(heading).display() #h(0.5em) #it.body])
      v(-0.8em)
      line(length: 100%, stroke: 0.8pt + rule-color)
    })
  }
  show heading.where(level: 2): it => {
    v(1em, weak: true)
    block(below: 0.6em, sticky: true, text(size: 13pt, weight: "bold", fill: accent, [#counter(heading).display() #h(0.4em) #it.body]))
  }
  show heading.where(level: 3): it => {
    v(0.7em, weak: true)
    block(below: 0.5em, sticky: true, text(size: 11pt, weight: "bold", [#counter(heading).display() #h(0.4em) #it.body]))
  }

  show raw: set text(font: font-mono)
  // show raw.where(block: false): it => box(fill: code-bg, inset: (x: 3pt), outset: (y: 3pt), radius: 2pt, it)
  show raw.where(block: true): it => block(
    width: 100%, fill: code-bg, inset: 10pt, radius: 4pt, stroke: (left: 2.5pt + accent), it,
  )

  set table(
    stroke: none, inset: (x: 8pt, y: 6pt), align: left + horizon,
    fill: (_, y) => if y == 0 { accent } else if calc.odd(y) { code-bg } else { white },
  )
  show table.cell: set text(size: 9.5pt)
  show table.cell.where(y: 0): set text(fill: white, weight: "bold", font: font-sans, size: 9pt)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.caption: it => text(size: 9pt, fill: muted, [
    #text(weight: "bold", font: font-sans, fill: ink)[#it.supplement #context it.counter.display(it.numbering)]
    #h(0.3em) #it.body
  ])
  show figure: set block(breakable: true, above: 1.3em, below: 1.3em)

  set list(marker: (text(fill: accent)[•], text(fill: accent)[‣]), indent: 0.6em)
  set enum(numbering: n => text(fill: accent, weight: "bold")[#n.], indent: 0.6em)
  show link: set text(fill: accent)
  show ref: set text(fill: accent)

  title-block(title, subtitle, authors, group, course, version, date)
  body
}


#let encoding(fmt) = cetz.canvas({
  import cetz.draw: *
  set-style(stroke: 0.7pt)
  rect((0, 0), (32, 1))

  let curr = 0
  let i = 20
  for block in fmt {
    rect((curr, 0), (curr + block.width, 1), fill: color.map.rainbow.at(i).lighten(50%))

    content((curr + block.width / 2, .5), align(center, raw(block.label) + [\ ] + v(-0.7em) + text(0.8em)[#block.name]))
    content((curr + block.width / 2, -.2), text(0.8em, [#block.width]))

    content((curr + 0.1, 1.1), text(0.8em, $#(31 - curr)$), anchor: "south-west")
    curr += block.width
    content((curr - 0.1, 1.1), text(0.8em, $#(31 - curr + 1)$), anchor: "south-east")
    i += 40
  }

}, x: (0.5, 0, 0))
