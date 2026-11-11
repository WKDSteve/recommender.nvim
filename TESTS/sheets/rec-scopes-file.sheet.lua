-- Live check: `path`, `cfile`, `line`, and `treesitter` refusing them, section 2 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.scopes-file",
  feature = "rec.scopes",
  title = "recommender.nvim: path, cfile in the order of gf, line with threshold 1, treesitter refuses all of them",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.write("a.lua", _G.uses("alpha.one", 5))
      _G.write("sub/b.lua", _G.uses("beta.two", 3))
      _G.write("far/only_path.lua", _G.uses("gamma.three", 3))
      _G.open("sub/start.lua", _G.uses("beta.two", 1))]],
    },
    { keys = ":Recommender path<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "[PATH]") and _G.eq(_G.shown(), "beta.two")]], note = "only the buffer's own directory" },
    { expect = [[_G.has(_G.text(), "beta.two (4 hits)")]], note = "b.lua and this buffer" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },

    { lua = [[vim.cmd("enew!")]] },
    { keys = ":Recommender path<CR>", note = "an unnamed buffer" },
    { wait = [[_G.noted("path scope requires the current buffer to have a file path")]] },
    { expect = "#_G.floats() == 0", note = "no crash, no float" },

    { lua = [[_G.open("c.lua", { "sub/b.lua" })]], note = "as typed" },
    { keys = ":Recommender cfile<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "[CFILE]") and _G.eq(_G.shown(), "beta.two")]], note = "that one file" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { lua = [[_G.open("sub/rel.lua", { "b.lua" })]], note = "relative to the buffer" },
    { keys = ":Recommender cfile<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "beta.two")]] },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { lua = [[vim.o.path = "far"
      _G.open("c.lua", { "only_path.lua" })]], note = "through 'path'" },
    { keys = ":Recommender cfile<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "gamma.three")]] },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    {
      lua = [[_G.write("dup.lua", _G.uses("typed.wins", 3))
      _G.write("sub/dup.lua", _G.uses("relative.loses", 3))
      _G.open("sub/rel.lua", { "dup.lua" })]],
      note = "in both places",
    },
    { keys = ":Recommender cfile<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "typed.wins")]], note = "as typed comes first" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },

    { lua = [[_G.open("c.lua", { "local x = 1", "local y = alpha.one(1)" })
      vim.fn.cursor(2, 1)]] },
    { keys = ":Recommender line<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "[LINE]") and _G.eq(_G.shown(), "alpha.one")]], note = "threshold 1: once is enough" },
    { expect = [[_G.has(_G.text(), "alpha.one (1 hits)")]] },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },

    { lua = "_G.forget()" },
    { keys = ":Recommender treesitter cwd<CR>" },
    {
      wait = [[_G.noted("cwd scope isn't supported for analyzer \"treesitter\" — use one of: regex, javascript, python, perf")]],
    },
    { keys = ":Recommender treesitter path<CR>" },
    { wait = [[_G.noted("path scope isn't supported")]] },
    { keys = ":Recommender treesitter cfile<CR>" },
    { wait = [[_G.noted("cfile scope isn't supported")]] },
    { keys = ":Recommender treesitter line<CR>" },
    { wait = [[_G.noted("line scope isn't supported")]] },
    { expect = "#_G.floats() == 0", note = "never a fallback to buffer scope" },
  },
}
