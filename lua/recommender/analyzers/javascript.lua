---@module 'recommender.analyzers.javascript'
---Regex-based JavaScript/TypeScript chain analyzer. Fast, no parser dependency.
---Same rules as analyzers/regex.lua (see `recommender.chain_analyzer`); the
---differences are the identifier character class (`$` is valid in JS/TS
---identifiers) and the rendered alias (`const %s = %s;` instead of `local`).

return require("recommender.chain_analyzer").make({
  ident = "%w_$",
  fmt = "const %s = %s;",
})
