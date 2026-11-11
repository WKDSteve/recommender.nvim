-- Live check: the analyzer override on real buffers, section 3 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.analyzers",
  feature = "rec.analyzers",
  title = "recommender.nvim: treesitter skips comments and strings, javascript and python use their own declarations",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("t.lua", {
        "local a = alpha.one(1)",
        "local b = alpha.one(2)",
        "local c = alpha.one(3)",
        "-- ghost.chain",
        "-- ghost.chain",
        "-- ghost.chain",
        'local s = "ghost.chain"',
      })
      vim.bo.filetype = "lua"]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "alpha.one ghost.chain")]], note = "regex: the comments too" },
    { expect = [[package.loaded["recommender.analyzers.treesitter"] == nil]], note = "treesitter is not even loaded yet" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = ":Recommender treesitter<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "alpha.one")]], note = "treesitter: only the code" },
    { expect = [[package.loaded["recommender.analyzers.treesitter"] ~= nil]] },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },

    { lua = [[_G.open("x.js", { "foo.bar(1)", "foo.bar(2)", "foo.bar(3)" })]] },
    { keys = ":Recommender javascript<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.text(), "const bar = foo.bar;")]], note = "a declaration of its language" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { lua = [[_G.open("x.py", { "os.path(1)", "os.path(2)", "os.path(3)" })]] },
    { keys = ":Recommender python<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.text(), "path = os.path")]] },
    { expect = [[not _G.text():find("local", 1, true) and not _G.text():find("const", 1, true)]] },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },

    { lua = [[_G.open("t.lua", { "local x = 1" })]], note = "a Lua buffer, the other files by scope" },
    { keys = ":Recommender javascript cwd<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "foo.bar")]], note = "only *.js" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = ":Recommender python path<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "os.path")]], note = "only *.py" },
  },
}
