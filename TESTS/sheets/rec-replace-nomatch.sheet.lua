-- Live check: a `:Replace` that opens no picker, section 6 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.replace-nomatch",
  title = "recommender.nvim: :Replace opens no picker it knows: after 5 seconds a warning, not silence",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      vim.api.nvim_create_user_command("Replace", function() end, { nargs = "*" })
      _G.open("t.lua", _G.sample())
      _G.source = vim.api.nvim_get_current_buf()]],
    },
    { keys = ":Recommender -r<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "<CR>" },
    { wait = [[pcall(_G.noted, "alpha.one")]], timeout = 8000 },
    { expect = [[_G.noted("alias not inserted")]] },
    { expect = "_G.eq(vim.api.nvim_buf_line_count(_G.source), #_G.sample())", note = "nothing inserted" },
  },
}
