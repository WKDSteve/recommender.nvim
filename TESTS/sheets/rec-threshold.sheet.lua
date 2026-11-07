-- Live check: the threshold forms, section 5 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.threshold",
  title = "recommender.nvim: positional, --threshold, -t and a count mean the same, the flag wins, order does not matter",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("t.lua", _G.sample())
      _G.two = "2 suggestions"
      _G.all = "4 suggestions"]],
    },
    { keys = ":Recommender regex 5<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = "_G.has(_G.title(), _G.two)", note = "alpha.one and beta.two" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = ":Recommender regex --threshold=5<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = "_G.has(_G.title(), _G.two)" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = ":Recommender -t 5<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = "_G.has(_G.title(), _G.two)" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = "5<leader>lrr" },
    { wait = "_G.open_float()" },
    { expect = "_G.has(_G.title(), _G.two)", note = "a count on the key" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = ":Recommender regex --threshold=3 5<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = "_G.has(_G.title(), _G.all)", note = "the flag wins over the positional 5" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = "<leader>lrr" },
    { wait = "_G.open_float()" },
    { expect = "_G.has(_G.title(), _G.all)", note = "no count: config.threshold, not 1" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = ":Recommender 5 regex cwd<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), _G.two) and _G.has(_G.title(), "[PROJECT]")]] },
    { lua = "_G.first = _G.shown()" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = ":Recommender cwd regex 5<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    {
      expect = [[_G.has(_G.title(), _G.two) and _G.has(_G.title(), "[PROJECT]") and _G.eq(_G.shown(), _G.first)]],
      note = "the same",
    },
  },
}
