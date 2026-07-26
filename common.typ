#import "deps.typ": fontawesome, itemize
#import "model.typ": *

#import itemize as el

#let continued-table = state("continued-table", false)
#let page-both = state("page-both", false)

#let styled-text(config, body) = {
  set text(
    font: config.font.serif,
    size: 11pt,
    lang: "zh",
    region: "cn",
    fallback: false,
  )
  show regex(
    "[，。．、：；？！”’》）』」】〗〕〉］｝“‘《（『「【〖〔〈［｛]+",
  ): it => it.text.replace("。", "．")
  show "·": set text(features: ("fwid",))
  show smartquote: set text(font: config.font.en)
  set super(typographic: false)
  set sub(typographic: false)
  show strong: it => {
    set text(fill: config.color.tint._800) if text.fill == black
    it
  }
  show emph: it => panic("Italic for Chinese is not implemented.")
  set footnote(numbering: "i)")
  set footnote.entry(indent: config.spacing.first-line-indent)

  body
}

#let styled-par(config, body) = {
  set par(
    leading: config.spacing.line-leading,
    spacing: config.spacing.par-spacing,
    justify: true,
  )

  body
}

#let styled-page(config, body) = {
  set page(
    margin: config.spacing.margin,
    header: context {
      let count = here().page()
      if skipped-header(count) {
        return
      }

      let title = query(heading.where(level: 1).before(here()))
      if title.len() == 0 {
        return
      }

      let phi = (1 + calc.sqrt(5)) / 2
      show: align.with(right)
      set text(font: config.font.sans, fill: config.color.tint._800, size: .75em)
      stack(
        dir: ltr,
        spacing: 1em / phi,
        title.last().body,
        move(dy: .15em, box(fill: config.color.tint._800, height: 1em, width: 1em / phi)),
      )
    },
    footer: grid(
      columns: (auto, 1fr, auto),
      align: (left, center, right),
      config.footer-content,
      [],
      context if page.numbering != none {
        tnum(counter(page).display(page.numbering, both: page-both.get()))
      },
    ),
  )

  body
}

#let styled-outline(config, body) = {
  import outline.entry

  set outline(indent: 1.5em)
  show outline: set heading(outlined: true)
  show entry.where(level: 1): set entry(fill: line(
    length: 100%,
    stroke: (thickness: .5pt, paint: config.color.tint._800.mix((white, 200%))),
  ))
  show entry: it => {
    let get-indent(level) = h(if type(outline.indent) == relative {
      level * outline.indent
    } else if type(outline.indent) == function {
      outline.indent(level)
    } else {
      panic("Unsupported outline indent type (such as `auto`).")
    })
    let body-transform(level, body) = {
      set text(font: config.font.sans, weight: "medium", fill: config.color.tint._800) if level == 0
      body
    }
    let prefix-transform(level, body) = {
      body-transform(level, body)
      if body != none {
        h(.25em)
      }
    }
    let page-transform(level, body) = {
      set text(fill: config.color.tint._800) if level == 0
      body
    }

    let indent = get-indent(it.level - 1)
    let prefix = prefix-transform(it.level - 1, it.prefix())
    let body = body-transform(it.level - 1, it.body()) + box(width: 1fr, pad(x: .25em, it.fill))
    let page = page-transform(it.level - 1, it.page())

    link(
      it.element.location(),
      grid(
        columns: (auto, auto, 1fr, auto),
        align: (auto, right + top, auto, bottom),
        indent,
        ..if "child" in prefix.fields() {
          (grid.cell(colspan: 2, body),)
        } else {
          // call `tnum` here is rather than in `let prefix` to avoid the problem brought by `if body != none` in `prefix-transform`.
          (it.indented(gap: 0pt, tnum(prefix), none), body)
        },
        tnum(page),
      ),
    )
  }

  body
}

#let styled-heading(config, body) = {
  let smart-link = model-factory(config).smart-link

  set heading(supplement: [套题], outlined: false)
  show heading.where(level: 1): set heading(outlined: true)
  show heading: set text(font: config.font.sans, fill: config.color.tint._800)
  show heading: set block(above: 1em, below: 1em)

  show heading.where(level: 1): it => {
    counter(footnote).update(())

    pagebreak(weak: true)

    let width = measure(it).width
    let container-width = page.width - (config.spacing.margin.left + config.spacing.margin.right)
    set text(size: calc.min(container-width / width, 1) * 1em)
    show: align.with(center)

    show <link-to-outline>: it => {
      let retreat = 1em
      let block-width = .25em
      show: block.with(
        width: 100%,
        outset: (x: retreat, y: .3em),
        radius: (left: .1em),
        stroke: (
          bottom: (paint: config.color.tint._800, thickness: .05em),
          left: (paint: config.color.tint._800, thickness: block-width),
        ),
      )
      place(
        dx: -(retreat + block-width / 2 + .3em + 1em),
        smart-link(quiet: true, <outline>, move(dy: -.2em, fontawesome.fa-cubes(solid: true))),
      )
      it
    }

    it
    [#metadata(none) <skip-header>]
  }

  body
}

#let link-to-outline(body) = {
  show heading.where(level: 1): it => [ #it <link-to-outline> ]

  body
}

#let numbered-heading(body) = {
  show heading: set heading(numbering: none)
  show heading.where(level: 1): set heading(numbering: (..nums) => {
    numbering("1", ..nums.pos())
    h(.5em, weak: true)
  })

  body
}

#let styled-figure(config, body) = {
  show figure: set block(breakable: true)
  show figure.where(kind: table): set figure.caption(position: top)

  body
}

#let styled-math-equation(config, body) = {
  import math: *

  show equation: set text(font: config.font.math + config.font.serif, weight: "regular")
  show sym.zwj: set text(fill: white) // Adapt to Stix2
  set mat(row-gap: .25em, column-gap: .75em)
  set cases(gap: .5em)
  set math.accent(dotless: false)
  show math.equation: set text(top-edge: "bounds", bottom-edge: "bounds")

  body
}

#let styled-enum-list(config, body) = {
  show: el.set-default(
    is-full-width: true,
    fill: config.color.tint._800,
    spacing: config.spacing.list-spacing,
    list-config: (
      indent: config.spacing.list-indent,
    ),
  )

  set list(marker: (text(baseline: -.125em)[•], [◦], [⁃]).map(
    it => box(width: 1em, align(center, it)) + h(-.5em),
  ))
  set terms(
    spacing: config.spacing.list-spacing,
    hanging-indent: config.spacing.terms-hanging-indent,
  )
  show terms: it => {
    show: el.set-default(hanging-indent: -config.spacing.first-line-indent) // bug of itemize: workaround
    it
  }

  body
}

#let styled-raw(config, body) = {
  set raw(tab-size: 2)
  show raw: set text(font: config.font.mono + config.font.sans)

  show raw.where(block: true): it => {
    if it.lines.len() == 0 {
      return it
    }

    let line-number-width = .5em * str(it.lines.first().count).len() + 1.5em
    let dark-paint = config.color.tint.light

    show: block.with(fill: dark-paint, radius: .5em)
    show: pad.with(2pt)
    stack(..it.lines.map(line => box(
      radius: .25em,
      fill: if calc.rem(line.number, 2) == 0 {
        dark-paint.mix((white, 200%))
      },
      grid(
        columns: (line-number-width, 1fr),
        align: (right + top, it.align + top),
        inset: .5em,
        text(fill: config.color.tint._800, str(line.number)), line,
      ),
    )))
  }

  body
}

#let styled-table(config, body) = {
  import table: *

  set table(
    align: center + horizon,
    stroke: (x: none, y: (paint: config.color.tint._800, thickness: .5pt)),
    inset: config.spacing.table-inset,
  )
  show table: set par(leading: .65em)
  set hline(stroke: (paint: config.color.tint._800, thickness: .5pt))
  set vline(stroke: (paint: config.color.tint._800, thickness: .5pt))

  show figure.where(kind: table): set block(breakable: true)
  show table: it => continued-table.update(false) + it

  body
}

#let styled-hyper(config, body) = {
  let styling(it) = underline(
    background: true,
    stroke: (
      paint: config.color.tint._100,
      thickness: .25em,
    ),
    offset: -.05em,
    evade: false,
    text(fill: config.color.tint._800, it),
  )

  show link: styling
  show ref: styling
  show cite: styling

  body
}

#let styled-divider(config, body) = {
  show divider: align(center, line(
    length: 110%,
    stroke: (
      paint: config.color.tint._500,
      thickness: 2pt,
      cap: "round",
      dash: (1em, .75em),
    ),
  ))
  show divider: set block(above: 1em, below: 1em)

  body
}

#let styled-universal(config, body) = {
  show: styled-page.with(config)
  show: styled-text.with(config)
  show: styled-par.with(config)
  show: styled-heading.with(config)
  show: styled-enum-list.with(config)
  show: styled-figure.with(config)
  show: styled-table.with(config)
  show: styled-math-equation.with(config)
  show: styled-raw.with(config)
  show: styled-divider.with(config)

  body
}

#let set-document-metadata(
  info: (
    author: (),
    title: none,
    date: auto,
  ),
  it,
) = {
  set document(
    author: info.author,
    title: info.title,
    date: info.date,
  )

  it
}

#let indented-par(config, body) = {
  set par(first-line-indent: (amount: config.spacing.first-line-indent, all: true))

  body
}

#let show-foreword(config, body) = {
  show: styled-universal.with(config)
  show: indented-par.with(config)
  show: styled-hyper.with(config)

  set page(numbering: "I")
  page-both.update(false)
  counter(page).update(1)

  body
}

#let show-outline(config, body) = {
  show: styled-universal.with(config)
  show: styled-outline.with(config) // no need to show elsewhere, rather than not able to

  set page(numbering: "I")
  page-both.update(false)

  body
}

#let show-body-start(config, body) = {
  show: numbered-heading

  set page(numbering: "1 / 1")
  page-both.update(true)
  counter(page).update(1)

  body
}

#let show-body-file(config, body) = {
  show: styled-universal.with(config)
  show: link-to-outline
  show: styled-hyper.with(config)

  set page(numbering: "1 / 1")
  page-both.update(true)

  body
}

#let show-appendix(config, body) = {
  show: styled-universal.with(config)
  show: indented-par.with(config)

  counter(heading).update(0)
  show heading.where(level: 1): set heading(numbering: (..nums) => {
    numbering("附录 A", ..nums)
    h(.5em, weak: true)
  })
  set page(numbering: "1·附录") // codepoint · enables fwid feature
  page-both.update(false)

  body
}
