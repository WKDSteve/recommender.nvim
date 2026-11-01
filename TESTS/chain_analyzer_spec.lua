-- TESTS/chain_analyzer_spec.lua — the factory behind the regex, javascript and
-- python analyzers: one implementation, parameterised by identifier class and
-- alias template, instead of three copies that must be fixed together.

return function(H)
  local make = require("recommender.chain_analyzer").make

  -- A fourth language costs one call, no copied module ------------------------
  local ruby = make({ ident = "%w_", fmt = "%s = %s # alias" })
  local res = ruby.analyze(2, {}, {}, { "File.dirname.to_s", "File.dirname.to_s" })
  local hit = H.find(res, "File.dirname")
  H.ok(hit, "a factory-made analyzer reports the shared prefix")
  H.eq(hit.alias, "dirname = File.dirname # alias", "the template is applied to the last segment")

  -- The identifier class decides what a chain boundary is ------------------------
  local strict = make({ ident = "%w_", fmt = "%s = %s" })
  local loose = make({ ident = "%w_$", fmt = "%s = %s" })
  local lines = { "this.$refs.foo", "this.$refs.foo" }
  H.ok(H.find(loose.analyze(2, {}, {}, lines), "this.$refs"), "`$` joins the chain with the permissive class")
  H.ok(not H.find(strict.analyze(2, {}, {}, lines), "this.$refs"), "`$` splits the chain with the strict class")

  -- Custom aliases win over the derived name ------------------------------------
  local custom = ruby.analyze(1, { ["File.dirname"] = "dn" }, {}, { "File.dirname" })
  H.eq(H.find(custom, "File.dirname").alias, "dn = File.dirname # alias", "custom alias replaces the derived name")

  -- Bad specs fail at construction, not at the first analyze() ---------------------
  H.ok(not pcall(make, { ident = "%w_" }), "a spec without `fmt` is rejected")
  H.ok(not pcall(make, "x"), "a non-table spec is rejected")

  -- The three shipped backends are thin wrappers, not copies -----------------------
  local root = vim.fs.root(debug.getinfo(1, "S").source:sub(2), "lua") or "."
  for _, name in ipairs({ "regex", "javascript", "python" }) do
    local path = root .. "/lua/recommender/analyzers/" .. name .. ".lua"
    local body = table.concat(vim.fn.readfile(path), "\n")
    H.ok(body:find("recommender.chain_analyzer", 1, true), name .. ": built by the shared factory")
    H.ok(not body:find("gmatch", 1, true), name .. ": carries no private extractor copy")
  end
end
