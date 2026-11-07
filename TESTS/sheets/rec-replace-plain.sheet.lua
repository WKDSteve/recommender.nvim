-- Live check: what replace mode does without `:Replace` and for what it cannot replace, section 6 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.replace-plain",
  title = "recommender.nvim: -r without :Replace, and -r on javascript or perf, is a plain insert",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("t.lua", _G.sample())
      _G.source = vim.api.nvim_get_current_buf()]],
    },
    { keys = ":Recommender -r<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "<CR>" },
    {
      wait = [[vim.api.nvim_buf_get_lines(_G.source, 0, 1, false)[1] == "local one = alpha.one"]],
      note = "no :Replace: the declaration",
    },
    { expect = [[_G.eq(table.concat(_G.notes, "|"), "")]], note = "quietly" },

    {
      lua = [[_G.fake_replace()
      _G.open("x.js", { "foo.bar(1)", "foo.bar(2)", "foo.bar(3)" })
      _G.source = vim.api.nvim_get_current_buf()]],
      note = "now with a :Replace",
    },
    { keys = ":Recommender -r javascript<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "<CR>" },
    { wait = [[vim.api.nvim_buf_get_lines(_G.source, 0, 1, false)[1] == "const bar = foo.bar;"]], note = "javascript: plain" },
    { expect = "_G.eq(#_G.replace_calls, 0)", note = ":Replace was not called" },

    {
      lua = [[_G.open("p.lua", { "for i = 1, 3 do", "  table.insert(t, i)", "end" })
      _G.source = vim.api.nvim_get_current_buf()]],
    },
    { keys = ":Recommender -r perf 1<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "<CR>" },
    { wait = [[vim.api.nvim_buf_get_lines(_G.source, 0, 1, false)[1]:find("-- perf: ", 1, true) ~= nil]], note = "perf: plain" },
    { expect = "_G.eq(#_G.replace_calls, 0)" },
  },
}
