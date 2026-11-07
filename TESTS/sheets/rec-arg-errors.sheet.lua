-- Live check: wrong arguments and an analyzer that cannot run, section 3 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.arg-errors",
  title = "recommender.nvim: a typo is an error and runs nothing, a broken buffer is no error, a broken parser is said",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("t.lua", _G.sample())]],
    },
    { keys = ":Recommender foo<CR>" },
    {
      wait = [[_G.noted("unrecognized argument: foo — expected an analyzer (regex, treesitter, javascript, python, perf), a scope (buffer, path, cwd, cfile, line), or a threshold number")]],
    },
    { settle = 2000 },
    { expect = "#_G.floats() == 0", note = "no default scan" },
    { lua = "_G.forget()" },
    { keys = ":Recommender --bogus<CR>", ignore_errmsg = true },
    { wait = [[_G.noted("bogus")]], note = "a hard error too" },
    { settle = 2000 },
    { expect = "#_G.floats() == 0", note = "no default scan" },

    {
      lua = [[_G.forget()
      _G.open("broken.lua", { "local x = (", "function f(", "local y = alpha.one(1)" })
      vim.bo.filetype = "lua"]],
    },
    { keys = ":Recommender treesitter 1<CR>" },
    {
      wait = [[_G.open_float() or table.concat(_G.notes, "|"):find("No suggestions (threshold: 1)", 1, true)]],
      note = "chains or none",
    },
    { expect = [[not table.concat(_G.notes, "|"):find("Error", 1, true)]], note = "no Lua error" },
    { keys = ":lua require('ui.kit').chooser.close()<CR>" },

    {
      lua = [[_G.forget()
      _G.open("t.lua", _G.sample())
      vim.bo.filetype = "lua"
      vim.treesitter.get_parser = function() error("no parser") end]],
    },
    { keys = ":Recommender treesitter<CR>" },
    { wait = [[_G.noted("treesitter analyzer could not analyze this buffer — see :checkhealth recommender")]] },
    { expect = [[not table.concat(_G.notes, "|"):find("No suggestions", 1, true)]], note = "not an empty buffer" },
    { expect = "#_G.floats() == 0" },
  },
}
