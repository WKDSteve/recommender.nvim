-- Live check: the compact layout, section 9 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.layout",
  title = "recommender.nvim: compact: one line per suggestion, j and k still by suggestion",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ float_layout = "compact", threshold = 2 })
      _G.sandbox()
      _G.open("t.lua", _G.sample())]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(vim.api.nvim_buf_line_count(0), 4)]], note = "one line each" },
    { expect = [[_G.eq(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1], "→ alpha.one (6)  local one = alpha.one")]] },
    { keys = "j" },
    { expect = [[_G.eq(_G.current(), "beta.two")]] },
    { keys = "j" },
    { expect = [[_G.eq(_G.current(), "gamma.three")]] },
    { keys = "k" },
    { expect = [[_G.eq(_G.current(), "beta.two")]] },
  },
}
