#import "deps.typ": fletcher

#import fletcher: diagram, edge, node

#let tnum = text.with(number-width: "tabular")

#let hbox(body) = context {
  let height = measure(body).height
  box(baseline: (height - 1em) / 2, body)
}

#let skipped-by-label(label, count) = query(label).any(pos => pos.location().page() == count)
#let skipped-header = skipped-by-label.with(<skip-header>)

#let attention-page(..args) = {
  assert(
    args.pos().len() == 1,
    message: "attention-page takes exactly 1 positional argument as `body`.",
  )

  let body = args.pos().first()
  page(
    header: none,
    numbering: none,
    align(center + horizon, body),
  )
}

#let parse-inset(inset-got, default: none) = {
  let sides = ("top", "bottom", "left", "right")

  if type(inset-got) == length {
    return sides.map(side => (side, inset-got)).to-dict()
  }

  if inset-got == auto and default == none {
    panic("Inset cannot be auto if no default is provided.")
  }

  if type(inset-got) not in (type(auto), dictionary) {
    panic("Invalid inset type: " + str(type(inset-got)))
  }

  let inset = sides.map(side => (side, auto)).to-dict()
  let default-parsed = if default != none {
    parse-inset(default)
  }

  if type(inset-got) == dictionary {
    for (key, value) in inset-got.pairs() {
      if key in sides {
        inset.insert(key, value)
      } else if key == "x" {
        inset.left = value
        inset.right = value
      } else if key == "y" {
        inset.top = value
        inset.bottom = value
      } else if key != "rest" {
        panic("Invalid inset key: " + key)
      }
    }

    if "rest" in inset-got {
      for side in sides {
        if inset.at(side) == auto {
          inset.insert(side, inset-got.rest)
        }
      }
    }
  }

  if default-parsed != none {
    for side in sides {
      if inset.at(side) == auto {
        inset.insert(side, default-parsed.at(side))
      }
    }
  }

  inset
}
