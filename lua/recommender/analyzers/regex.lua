---@module 'recommender.analyzers.regex'
---Regex-based Lua chain analyzer. Fast, no parser dependency.
---Collects 3-part chains first (e.g., vim.api.nvim_*), then 2-part; the
---shared logic lives in `recommender.chain_analyzer`.

return require("recommender.chain_analyzer").make({
  ident = "%w_",
  fmt = "local %s = %s",
})
