-- Bold and underline the site owner's name ("Aggarwal, A.") in the reference list.
-- Must run after citeproc (see `filters` in _quarto.yml).
local function is_space(el)
  return el.t == "Space" or (el.t == "Str" and el.text == "\u{a0}")
end

function Div(div)
  if div.identifier ~= "refs" then return nil end
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
