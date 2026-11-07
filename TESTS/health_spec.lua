-- TESTS/health_spec.lua -- what `:checkhealth recommender` says about the Lua Tree-sitter parser. The bundled grammar
-- has no `field_expression` node (it is `dot_index_expression`), so a probe for the old name read as "parser not found"
-- with the parser right there.

return function(H)
  local saved = {}
  local lines = {}
  for _, level in ipairs({ "start", "ok", "info", "warn", "error" }) do
    saved[level] = vim.health[level]
    vim.health[level] = function(msg)
      lines[#lines + 1] = level .. ": " .. msg
    end
  end

  local ok, err = pcall(require("recommender.health").check)

  for level, fn in pairs(saved) do
    vim.health[level] = fn
  end
  H.ok(ok, err)

  -- The analyzer's own query is what decides whether analyzer = "treesitter" works.
  H.ok(pcall(vim.treesitter.query.parse, "lua", "(dot_index_expression) @field"), "this Neovim has the Lua parser")
  local all = table.concat(lines, "\n")
  H.ok(all:find('ok: Lua Tree-sitter parser found (analyzer = "treesitter" available)', 1, true), "the parser is reported")
  H.falsy(all:find("parser not found", 1, true), "and not as missing")
end
