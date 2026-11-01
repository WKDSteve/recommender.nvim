---@module 'recommender.chain_analyzer'
---Factory for the regex-based chain analyzers (Lua, JavaScript, Python).
---The backends differ only in the identifier character class and in the
---rendered alias declaration, so both are parameters here and each backend
---file is a one-line `make(...)` call.

local blacklist = require("recommender.blacklist")

local M = {}

---@class recommender.ChainSpec
---@field ident string  Lua pattern character class body for one identifier char, e.g. `%w_`
---@field fmt string    `string.format` template taking the alias name then the chain, e.g. `local %s = %s`

---@param ident string
---@return fun(line: string): string[]
local function make_extractor(ident)
  local two = ("([%s]+%%.[%s]+)"):format(ident, ident)
  local three = ("([%s]+%%.[%s]+%%.[%s]+)"):format(ident, ident, ident)
  return function(line)
    local out = {}
    for c in line:gmatch(three) do
      out[#out + 1] = c
    end
    for c in line:gmatch(two) do
      out[#out + 1] = c
    end
    return require("lib.lua.tables").dedup_list(out)
  end
end

---Build an analyzer module for one language.
---@param spec recommender.ChainSpec
---@return table analyzer  Module with `analyze(threshold, custom_aliases, bl, lines)`
function M.make(spec)
  assert(
    type(spec) == "table" and type(spec.ident) == "string" and type(spec.fmt) == "string",
    "chain_analyzer.make: spec needs string `ident` and `fmt`"
  )
  local extract_chains = make_extractor(spec.ident)
  local last_pat = ("([%s]+)$"):format(spec.ident)
  local analyzer = {}

  ---Analyze a buffer (or an explicit line list) and return alias suggestions.
  ---@param threshold integer
  ---@param custom_aliases table<string,string>
  ---@param bl string[]
  ---@param lines string[]|nil  Explicit lines to scan (e.g. concatenated project
  ---                            files for cwd scope); defaults to the current
  ---                            buffer's lines when omitted.
  ---@return {chain:string, count:integer, alias:string}[]
  function analyzer.analyze(threshold, custom_aliases, bl, lines)
    local counts = {}
    lines = lines or vim.api.nvim_buf_get_lines(0, 0, -1, false)

    for _, line in ipairs(lines) do
      for _, chain in ipairs(extract_chains(line)) do
        if not blacklist.is_blacklisted(chain, bl) then
          counts[chain] = (counts[chain] or 0) + 1
        end
      end
    end

    local res = {}
    for chain, count in pairs(counts) do
      if count >= threshold then
        local name
        if custom_aliases and custom_aliases[chain] then
          name = custom_aliases[chain]
        else
          name = chain:match(last_pat) or chain:gsub("%.", "_")
        end
        res[#res + 1] = { chain = chain, count = count, alias = spec.fmt:format(name, chain) }
      end
    end

    table.sort(res, function(a, b)
      return a.count > b.count
    end)
    return res
  end

  return analyzer
end

return M
