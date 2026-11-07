-- Live check: ui.nvim's badge before the plugin is loaded, section 11 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.statusline-badge",
  title = "recommender.nvim: ui.nvim's recommender_badge renders empty before the plugin loads and does not pull it in",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.sandbox()
      _G.open("t.lua", _G.sample())]],
    },
    { expect = [[package.loaded["recommender.statusline"] == nil and package.loaded["recommender"] == nil]], note = "fresh" },
    { lua = [[_G.badge = require("ui.statusline.modules.recommender_badge")]] },
    { expect = [[_G.eq(_G.badge(), "")]], note = "empty" },
    {
      expect = [[package.loaded["recommender.statusline"] == nil and package.loaded["recommender"] == nil]],
      note = "and nothing of the plugin loaded by it",
    },
    { lua = [[require("recommender").setup({})
      require("recommender.statusline")]], note = "once it is there" },
    { expect = [[_G.eq(_G.badge(), " 4 alias suggestions open for this file ")]] },
  },
}
