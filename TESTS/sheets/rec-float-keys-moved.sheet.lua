-- Live check: a moved float key and the help, section 10 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.float-keys-moved",
  title = "recommender.nvim: float_keymaps = { yank = ... } moves the key, the help lists what is bound",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ float_keymaps = { yank = "Y", ignore = false } })
      _G.sandbox()
      _G.open("t.lua", _G.sample())]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "Y" },
    { expect = [[_G.eq(vim.fn.getreg("+"), "local one = alpha.one")]], note = "the moved key" },
    { lua = "_G.forget()" },
    { keys = "?" },
    { expect = [[_G.noted("Recommender keymaps:")]] },
    { expect = [[_G.noted("yank alias to clipboard") and _G.noted("  Y ")]], note = "what is bound" },
    { expect = [[not table.concat(_G.notes, "|"):find("ignore entry", 1, true)]], note = "not what is dropped" },
  },
}
