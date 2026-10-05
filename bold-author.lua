-- Bold and underline the site owner's name ("Aggarwal, A.") in the reference list.
-- Quarto runs user filters before citeproc, so run citeproc here first.
local function is_space(el)
  return el.t == "Space" or (el.t == "Str" and el.text == "\u{a0}")
end

-- First-author entries first; each group keeps the CSL's newest-first order.
local function first_author_first(div)
  local mine, others = {}, {}
  for _, entry in ipairs(div.content) do
    if pandoc.utils.stringify(entry):match("^Aggarwal,") then
      mine[#mine + 1] = entry
    else
      others[#others + 1] = entry
    end
  end
  for _, e in ipairs(others) do mine[#mine + 1] = e end
  div.content = mine
  return div
end

-- Keep only the first n entries.
local function limit(div, n)
  local kept = {}
  for i = 1, math.min(n, #div.content) do kept[i] = div.content[i] end
  div.content = kept
  return div
end

-- `latest: N` in a page's front matter shows the N newest entries by date;
-- otherwise the full list is shown with first-author papers first.
local function highlight(div, latest)
  if latest then
    div = limit(div, latest)
  else
    div = first_author_first(div)
  end
  return div:walk({
    Inlines = function(inlines)
      for i = 1, #inlines - 2 do
        local a, b, c = inlines[i], inlines[i + 1], inlines[i + 2]
        if a.t == "Str" and a.text == "Aggarwal," and is_space(b)
           and c.t == "Str" and c.text:match("^A%.") then
          local trail = c.text:sub(3)  -- "," when more authors follow
          local name = pandoc.Strong({ pandoc.Underline({ a, pandoc.Space(), pandoc.Str("A.") }) })
          local out = pandoc.Inlines({})
          for j = 1, i - 1 do out:insert(inlines[j]) end
          out:insert(name)
          if trail ~= "" then out:insert(pandoc.Str(trail)) end
          for j = i + 3, #inlines do out:insert(inlines[j]) end
          return out
        end
      end
    end
  })
end

function Pandoc(doc)
  local latest = doc.meta.latest and tonumber(pandoc.utils.stringify(doc.meta.latest))
  doc = pandoc.utils.citeproc(doc)
  doc = doc:walk({
    Div = function(div)
      if div.identifier == "refs" then return highlight(div, latest) end
    end
  })
  -- citeproc has run; stop pandoc from running it a second time
  for _, k in ipairs({ "bibliography", "references", "nocite", "csl" }) do
    doc.meta[k] = nil
  end
  return doc
end
