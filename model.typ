#import "util.typ": *

#let model-factory(config) = {
  let tint = config.color.tint
  let border-stroke = (paint: config.color.tint._800, thickness: .5pt)

  let error = text.with(fill: config.color.error)
  let warning = text.with(fill: config.color.warning)
  let comment = text.with(fill: config.color.comment)
  let time(it) = strong(text(fill: config.color.time, it))
  let tag(it) = text(fill: config.color.tag)[\[#it\]]

  let todo(it) = [
    #box(
      inset: (x: .25em),
      box(
        stroke: (paint: config.color.todo),
        inset: (x: .25em),
        outset: (y: .25em),
        text(fill: config.color.todo)[TODO: #it],
      ),
    ) <todo>
  ]

  let quote(body) = {
    let margin = .75pt

    block(
      stroke: (left: (paint: config.color.tint._700, thickness: 2pt + 2 * margin)),
      inset: (left: margin, y: 2 * margin),
      block(
        width: 100%,
        fill: config.color.tint.light,
        radius: (right: .5em),
        stroke: (left: (paint: config.color.tint.light, thickness: 1pt + margin)),
        inset: .75em,
        text(fill: config.color.tint._800.mix(luma(128)))[

          #body
        ],
      ),
    )
  }

  let refn(pattern, ..args) = tnum(text(fill: config.color.tint._800, numbering(pattern, ..args)))

  let problem-level = state("problem-level", 0)

  let problem(..args) = {
    let args-named = args.named()
    let custom-numbering = args-named.remove(
      "numbering",
      default: args-named.remove("custom-numbering", default: auto),
    )

    set par(
      leading: config.spacing.problem-line-leading,
      spacing: config.spacing.problem-par-spacing,
    )
    problem-level.update(level => level + 1)
    enum(
      ..args-named,
      tight: false,
      spacing: config.spacing.problem-spacing,
      numbering: it => {
        let numbering-str = if custom-numbering == auto {
          ("一、", "1.", "(1)", "(i)").at(problem-level.get() - 1)
        } else if type(custom-numbering) == array {
          custom-numbering.at(problem-level.get() - 1)
        } else {
          custom-numbering
        }

        refn(numbering-str, it)
        if numbering-str.ends-with("、") { h(-.5em) }
      },
      ..args.pos(),
    )
    problem-level.update(level => level - 1)
  }
  let problem-alt = problem.with(numbering: ("一、", "(1)", "(i)"))
  let problem-English = problem.with(numbering: ("1.", "1)"))

  let blank-offset = 3em / 18
  let alt-blank = (ext: 0em, body) => context box(
    inset: (x: ext),
    outset: (bottom: blank-offset),
    stroke: (
      bottom: (
        paint: text.fill,
        thickness: .5pt,
      ),
    ),
    body,
  )
  let blank = box(
    width: 3em,
    outset: (bottom: blank-offset),
    stroke: (
      bottom: (
        paint: black,
        thickness: .5pt,
      ),
    ),
  )

  let circled(num) = if type(num) == int {
    "①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳".clusters().at(num - 1)
  } else {
    box(baseline: .2em, circle(radius: .5em, stroke: .5pt, align(center + horizon, num)))
  }

  let marks(n) = box[（#n 分）]
  let marks-alt(n) = box[(#n marks)]

  let choice-blank = "（" + h(1.5em) + "）"
  let cblank = choice-blank

  let choices(..args) = {
    let named = args.named()
    let inner-numbering = named.remove("numbering", default: "A.")

    named.align = named.at("align", default: left + horizon)

    let columns = named.at("columns", default: args.pos().len())
    if type(columns) == int {
      columns = (1fr,) * columns
    }
    named.columns = columns

    set enum(numbering: refn.with(inner-numbering))
    pad(y: -.5em, grid(
      inset: (y: .5em), ..named, ..args.pos().enumerate().map(((k, v)) => enum.item(k + 1, v))
    ))
  }

  let indented-list(..args) = context {
    let named = args.named()
    let title = named.at("title", default: none)
    let indent = named.at("indent", default: measure(title + sym.zws).width)

    title
    args.pos().join(parbreak() + h(indent))
  }

  let make-heading(tags: (), title-text: "", body) = {
    heading({
      tags.map(tag).join(" ")
      " "
      body
    })

    context [#metadata((
      tags: tags,
      title: title-text,
      page-logic: counter(page).get().first(),
      page-physical: here().page(),
    )) <problemset>]
  }

  let smart-link(quiet: false, dest, body) = context if query(dest).len() != 0 {
    link(dest, body)
  } else if quiet {
    link("dummy-link", body)
  } else {
    warning[\[Unresolved CrossRef: #body\]]
  }

  let table-impl(..args) = {
    import table: *

    let args-named = args.named()

    let vlines = args-named.remove("vlines", default: true)
    let header = args-named.remove("header", default: (_, _) => false)
    let transform = args-named.remove("header-transform", default: strong)
    let header-fill = args-named.remove("header-fill", default: config.color.tint.light)
    let columns = args-named.at("columns", default: 1)

    show cell: it => if header(it.x, it.y) {
      transform(it)
    } else {
      it
    }

    table(
      fill: (x, y) => if header(x, y) { header-fill },
      ..args-named,
      ..args.pos(),

      ..if vlines {
        let column-count = if type(columns) == array {
          columns.len()
        } else if type(columns) == int {
          columns
        } else if type(columns) in (type(auto), length, relative, fraction) {
          1
        }

        range(1, column-count).map(i => vline(x: i))
      } else {
        ()
      },
    )
  }

  let htable = table-impl.with(header: (x, y) => x == 0)
  let vtable = table-impl.with(header: (x, y) => y == 0)
  let bi-table = table-impl.with(header: (x, y) => x == 0 or y == 0)

  let diag-cell(..args) = {
    if args.pos().len() > 2 {
      panic("`diag-cell` takes at most 2 positional arguments, but got " + args.pos().len())
    }
    let bodies = (0, 1).map(
      i => text(top-edge: "bounds", bottom-edge: "bounds", args.pos().at(i, default: none)),
    )

    let args = args.named()
    let stroke = args.at("stroke", default: border-stroke)
    let inset-got = args.at("inset", default: auto)

    context {
      let sizes = bodies.map(measure)

      let inset = parse-inset(inset-got, default: config.spacing.table-inset)
      let inset-alt = inset
      let width = if "width" in args and args.width != auto {
        inset-alt.left = 0pt
        inset-alt.right = 0pt
        args.at("width")
      } else {
        2 * (calc.max(..sizes.map(it => it.width)) + inset.left + inset.right)
      }
      let height = if "height" in args and args.height != auto {
        inset-alt.top = 0pt
        inset-alt.bottom = 0pt
        args.at("height")
      } else {
        2 * (calc.max(..sizes.map(it => it.height)) + inset.top + inset.bottom)
      }

      table.cell(inset: inset, box(height: height, width: width, {
        place(bottom + left, dx: inset.left, dy: -inset.bottom, bodies.at(0))
        place(top + right, dx: -inset.right, dy: inset.top, bodies.at(1))
        place(top + left, line(
          start: (0% - inset-alt.left, 0% - inset-alt.top),
          end: (100% + inset-alt.right, 100% + inset-alt.bottom),
          stroke: stroke,
        ))
      }))
    }
  }

  let edge-label-wrapper = edge => text(fill: edge.stroke.paint, edge.label)
  let node-label-wrapper = label => text(fill: tint._800, label)
  let diagram-preset = (
    node-stroke: border-stroke,
    node-fill: config.color.tint.light,
    edge-stroke: border-stroke,
    label-wrapper: edge-label-wrapper,
  )
  let preset-edges = (
    edge: edge.with(marks: "-|>", label-sep: .25em),
    mutual-edge: edge.with(marks: "-|>", label-sep: .25em, bend: 30deg),
    self-edge: edge.with(marks: "-|>", label-sep: .25em, bend: 120deg, loop-angle: 90deg),
  )

  (
    tnum: tnum,
    error: error,
    warning: warning,
    comment: comment,
    time: time,
    tag: tag,
    todo: todo,
    quote: quote,
    refn: refn,
    problem: problem,
    p: problem,
    problem-alt: problem-alt,
    ps: problem-alt,
    problem-English: problem-English,
    pe: problem-English,
    blank-offset: blank-offset,
    alt-blank: alt-blank,
    blank: blank,
    circled: circled,
    marks: marks,
    marks-alt: marks-alt,
    choice-blank: choice-blank,
    cblank: cblank,
    choices: choices,
    indented-list: indented-list,
    make-heading: make-heading,
    smart-link: smart-link,
    htable: htable,
    vtable: vtable,
    bi-table: bi-table,
    diag-cell: diag-cell,
    edge-label-wrapper: edge-label-wrapper,
    node-label-wrapper: node-label-wrapper,
    diagram-preset: diagram-preset,
    preset-edges: preset-edges,
  )
}
