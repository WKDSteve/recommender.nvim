-- Live check: the default invocation in the float (task recommender.nvim/testblatt-bindings-checkliste; section 1 of
-- ALL/manual-test-checklists/recommender.md and the `:Recommender` line of the bindings checklist).
return {
  id = "rec.default",
  feature = "rec.float",
  title = "recommender.nvim: :Recommender opens the float, j/k, Enter, A, y and the toggle",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("sample.lua", _G.sample())
      _G.source = vim.api.nvim_get_current_buf()
      _G.before = _G.text()]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", note = "a float" },
    { expect = [[_G.has(_G.title(), "Recommender: 4 suggestions")]], note = "threshold 3: all four chains" },
    {
      expect = [[_G.eq(table.concat(vim.api.nvim_buf_get_lines(0, 0, 3, false), "|"),
        "→ alpha.one (6 hits)|  local one = alpha.one|")]],
      note = "chain, hit count and alias: the 3 lines of the detailed layout",
    },
    { expect = [[_G.eq(_G.shown(), "alpha.one beta.two delta.four gamma.three")]] },

    { lua = [[_G.row = vim.fn.line(".")]] },
    { keys = "j" },
    { expect = [[_G.eq(_G.current(), "beta.two") and _G.eq(vim.fn.line("."), _G.row + 3)]], note = "j: one suggestion" },
    { keys = "j" },
    { keys = "k" },
    { expect = [[_G.eq(_G.current(), "beta.two") and _G.eq(vim.fn.line("."), _G.row + 3)]], note = "k: one back" },

    { keys = "y" },
    { expect = [[_G.eq(vim.fn.getreg("+"), "local two = beta.two")]], note = "y: on the clipboard" },
    { expect = [[_G.noted("Yanked: local two = beta.two") and _G.open_float()]], note = "said, and the float stays" },
    { expect = [[_G.eq(_G.text(_G.source), _G.before)]], note = "y inserts nothing" },

    { keys = ":Recommender<CR>", note = "again, with the float open" },
    { wait = "#_G.floats() == 0", note = "the toggle closes it" },
    { settle = 2000 },
    { expect = "#_G.floats() == 0 and not _G.open_float()", note = "no second float on top" },
    { expect = "_G.eq(vim.api.nvim_get_current_buf(), _G.source)" },

    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()" },
    { keys = "j<CR>", note = "Enter on the second" },
    { wait = [[vim.api.nvim_buf_get_lines(_G.source, 0, 1, false)[1] == "local two = beta.two"]], note = "inserted" },
    { expect = "#_G.floats() == 0 and vim.api.nvim_get_current_buf() == _G.source", note = "back in the source buffer" },
    { expect = "_G.eq(vim.api.nvim_buf_line_count(0), #_G.sample() + 1)", note = "one line" },
    { keys = "u" },

    { lua = "_G.forget()" },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()" },
    { keys = "A" },
    { wait = "vim.api.nvim_buf_line_count(_G.source) == #_G.sample() + 4", note = "all four inserted" },
    { expect = [[_G.noted("Inserted 4 alias(es)")]] },
    {
      expect = [[_G.eq(table.concat(vim.api.nvim_buf_get_lines(_G.source, 0, 4, false), "|"),
        "local one = alpha.one|local two = beta.two|local three = gamma.three|local four = delta.four")]],
      note = "in the buffer the command ran in",
    },
    { keys = ":bwipeout!<CR>" },
  },
}
