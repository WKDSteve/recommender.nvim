-- Live check: the per-buffer ignore list, section 7 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.ignore",
  title = "recommender.nvim: Backspace hides a suggestion in this buffer only, U brings it back",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("a.lua", _G.sample())
      _G.first = vim.api.nvim_get_current_buf()]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.current(), "alpha.one")]] },
    { keys = "<BS>" },
    { wait = [[_G.open_float() and _G.shown() == "beta.two delta.four gamma.three"]], note = "gone, the float stays" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "beta.two delta.four gamma.three")]], note = "still gone on the same buffer" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { lua = [[_G.open("b.lua", _G.sample())]] },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.shown(), "alpha.one beta.two delta.four gamma.three")]], note = "another buffer: there" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { lua = [[vim.api.nvim_set_current_buf(_G.first)]] },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "U" },
    { wait = [[_G.open_float() and _G.shown() == "alpha.one beta.two delta.four gamma.three"]], note = "U restores it" },
  },
}
