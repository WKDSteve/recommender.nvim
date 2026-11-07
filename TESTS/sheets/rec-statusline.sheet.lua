-- Live check: the statusline component, section 11 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.statusline",
  title = "recommender.nvim: status() counts for the active config, follows edits, is empty on nothing and on failure",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("t.lua", _G.sample())
      vim.bo.filetype = "lua"
      _G.source = vim.api.nvim_get_current_buf()
      _G.sl = require("recommender.statusline")]],
    },
    { expect = [[_G.eq(_G.sl.status(), " 4 alias suggestions open for this file ")]] },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "4 suggestions")]], note = "the number the float shows" },
    { keys = "<BS>", note = "one dismissed" },
    { wait = [[_G.open_float() and _G.title():find("3 suggestions", 1, true)]] },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    {
      expect = [[_G.eq(_G.sl.status(), " 4 alias suggestions open for this file ")]],
      note = "still counted: it asks the analyzer",
    },
    { expect = "_G.eq(_G.sl.lualine_component(), _G.sl.status())", note = "the alias" },

    { lua = [[vim.cmd("enew!")]], note = "an empty scratch buffer" },
    { expect = [[_G.eq(_G.sl.status(), "") and _G.eq(table.concat(_G.notes, "|"), "")]], note = "empty, no notify" },
    { lua = [[_G.open("few.lua", _G.uses("alpha.one", 2))]], note = "nothing above the threshold" },
    { expect = [[_G.eq(_G.sl.status(), "")]] },
    { lua = [[_G.open("one.lua", _G.uses("alpha.one", 3))]] },
    { expect = [[_G.eq(_G.sl.status(), " 1 alias suggestion open for this file ")]], note = "the singular" },
    { lua = [[vim.api.nvim_set_current_buf(_G.source)]] },

    {
      lua = [[vim.api.nvim_buf_set_lines(0, 0, 0, false, _G.uses("fifth.chain", 3))]],
      note = "an edit: another repeated chain",
    },
    { expect = [[_G.eq(_G.sl.status(), " 5 alias suggestions open for this file ")]], note = "the count follows" },
    { lua = "_G.sl.invalidate(0)", note = "does not raise" },
    { expect = [[_G.eq(_G.sl.status(), " 5 alias suggestions open for this file ")]] },

    {
      lua = [[vim.api.nvim_buf_set_lines(0, 0, 0, false, { "local once = lonely.chain(1)" })
      _G.sl.status()
      require("recommender").setup({ threshold = 1 })]],
      note = "the threshold of the active config",
    },
    { expect = [[_G.eq(_G.sl.status():match("%d+") + 0 > 5, true)]], note = "the count rises, no edit needed" },

    { lua = [[vim.o.statusline = "[%{v:lua.require('recommender.statusline').status()}]"]], note = "the native statusline" },
    { expect = [[_G.has(vim.api.nvim_eval_statusline(vim.o.statusline, {}).str, " alias suggestions")]], note = "the badge" },
    { lua = [[vim.cmd("enew!")]] },
    { expect = [[_G.eq(vim.api.nvim_eval_statusline(vim.o.statusline, {}).str, "[]")]], note = "gone when there is nothing" },
    { lua = "vim.api.nvim_set_current_buf(_G.source)" },

    {
      lua = [[require("recommender").setup({ analyzer = "treesitter" })
      vim.treesitter.get_parser = function() error("no parser") end
      vim.api.nvim_buf_set_lines(0, 0, 0, false, { "-- force a recount" })]],
      note = "an analyzer that cannot run",
    },
    { expect = [[_G.eq(_G.sl.status(), "")]], note = "empty, never an error" },
  },
  manual = { "ui.nvim's recommender_badge in a real statusline variant: it appears, disappears and does not lag while typing" },
}
