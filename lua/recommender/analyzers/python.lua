---@module 'recommender.analyzers.python'
---Regex-based Python chain analyzer. Fast, no parser dependency.
---Same rules as analyzers/regex.lua (see `recommender.chain_analyzer`); the
---only difference is the rendered alias: Python has no `local`/`const`
---keyword, so the suggestion is a plain `%s = %s` assignment.

return require("recommender.chain_analyzer").make({
  ident = "%w_",
  fmt = "%s = %s",
})
