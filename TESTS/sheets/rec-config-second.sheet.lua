-- Live check: a second `setup()`, section 8 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.config-second",
  title = "recommender.nvim: a second setup() says so, applies at once, binds nothing twice and starts from the defaults",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ threshold = 3, float_layout = "compact" })
      _G.sandbox()
      _G.open("t.lua", vim.list_extend(_G.uses("many.times", 10), _G.sample()))
      _G.keys = #vim.api.nvim_get_keymap("n")]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "5 suggestions")]] },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { lua = [[require("recommender").setup({ threshold = 10 })]] },
    {
      expect = [[_G.noted("setup() called again — config re-merged and takes effect immediately; ")]],
      note = "an info, no error",
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "1 suggestion") and _G.eq(_G.shown(), "many.times")]], note = "threshold 10, no restart" },
    { expect = [[_G.has(_G.text(), "→ many.times (10 hits)")]], note = "float_layout left out: the default again" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { expect = "_G.eq(#vim.api.nvim_get_keymap('n'), _G.keys)", note = "not bound twice" },
    { expect = "_G.eq(vim.fn.exists(':Recommender'), 2)" },
  },
}
