-- Live check: moving and dropping one global key, section 10 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.keymaps-custom",
  title = "recommender.nvim: keymaps = { regex = ..., python = false } moves one key and drops another",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ keymaps = { regex = "<leader>zr", python = false } })
      _G.sandbox()
      _G.open("t.lua", _G.sample())]],
    },
    { expect = [[_G.bound("<leader>zr")]], note = "the new key" },
    { expect = [[not _G.bound("<leader>lrr")]], note = "the old one is gone" },
    { expect = [[not _G.bound("<leader>lrp")]], note = "python: absent" },
    { expect = [[_G.bound("<leader>lr") and _G.bound("<leader>lrt")]], note = "the others stay" },
    { keys = "<leader>zr" },
    { wait = "_G.open_float()", note = "runs the regex analyzer" },
  },
}
