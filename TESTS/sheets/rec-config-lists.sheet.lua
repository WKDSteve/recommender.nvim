-- Live check: blacklist and custom aliases, section 8 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.config-lists",
  feature = "rec.blacklist-aliases",
  title = "recommender.nvim: a blacklist blocks by prefix, a custom alias replaces the generated name",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ blacklist = { "vim.fn" }, custom_aliases = { ["vim.keymap.set"] = "my_set", ["foo.bar"] = "fb" } })
      _G.sandbox()
      _G.open("t.lua", vim
        .iter({ _G.uses("vim.fn.expand", 3), _G.uses("vim.fn.system", 3), _G.uses("vim.keymap.set", 3), _G.uses("foo.bar", 4) })
        :flatten()
        :totable())]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[not _G.text():find("vim.fn", 1, true)]], note = "vim.fn and everything under it: not even listed" },
    { expect = [[_G.has(_G.text(), "local my_set = vim.keymap.set")]], note = "the custom alias, not the default km_set" },
    { expect = [[_G.has(_G.text(), "local fb = foo.bar")]] },
  },
}
