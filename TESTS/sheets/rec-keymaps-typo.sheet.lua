-- Live check: a misspelled action name, section 10 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.keymaps-typo",
  title = "recommender.nvim: a misspelled action name in keymaps is reported",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ keymaps = { regeex = "<leader>x" } })
      _G.sandbox()]],
    },
    { expect = [[_G.noted("regeex")]], note = "reported" },
    { expect = [[not _G.bound("<leader>x")]], note = "and not bound" },
  },
}
