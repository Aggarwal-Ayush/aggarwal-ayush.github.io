-- Bold the site owner's name ("Aggarwal, A.") in the generated reference list.
function Div(div)
  if div.identifier ~= "refs" then return nil end
  return div:walk({
    Inlines = function(inlines)
      local i = 1
      while i < #inlines do
        local a, b, c = inlines[i], inlines[i + 1], inlines[i + 2]
        if a.t == "Str" and a.text == "Aggarwal," and b.t == "Space"
           and c and c.t == "Str" and c.text:match("^A%.") then
          local trail = c.text:sub(3)  -- e.g. "," when followed by more authors
          local bold = pandoc.Strong({ a, b, pandoc.Str("A.") })
          inlines[i] = bold
          inlines:remove(i + 1)
          if trail ~= "" then inlines[i + 1] = pandoc.Str(trail) else inlines:remove(i + 1) end
          return inlines
        end
        i = i + 1
      end
    end
  })
end
