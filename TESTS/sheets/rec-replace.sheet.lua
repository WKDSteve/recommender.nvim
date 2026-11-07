-- Live check: replace mode up to `:Replace`, with a stand-in for it, section 6 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.replace",
  title = "recommender.nvim: -r hands :Replace the chain, the alias and %, and inserts only after a picker that changed something",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.fake_replace()
      _G.open("t.lua", _G.sample())
      _G.source = vim.api.nvim_get_current_buf()
      _G.before = _G.text()]],
    },
    { keys = ":Recommender -r<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "[REPLACE MODE]")]] },
    { keys = "<CR>" },
    { wait = "_G.replace_calls[1] ~= nil and vim.bo.filetype == 'TelescopePrompt'", note = "the picker is open" },
    { expect = [[_G.eq(table.concat(_G.replace_calls[1], " "), '"alpha.one" one %')]], note = "chain, alias, this buffer" },
    { lua = "vim.wait(50)" },
    { expect = "_G.eq(_G.text(_G.source), _G.before)", note = "no declaration yet: the insert waits" },
    { lua = [[_G.apply("alpha.one", "one")]] },
    { wait = [[vim.api.nvim_buf_get_lines(_G.source, 0, 1, false)[1] == "local one = alpha.one"]], note = "now it is there" },
    { expect = "_G.eq(vim.api.nvim_buf_line_count(_G.source), #_G.sample() + 1)" },
    { lua = [[vim.api.nvim_buf_set_lines(_G.source, 0, -1, false, _G.sample())
      _G.replace_calls = {}]] },

    { keys = ":Recommender -r cwd<CR>", note = "after a scan of the tree" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "<CR>" },
    { wait = "_G.replace_calls[1] ~= nil and vim.bo.filetype == 'TelescopePrompt'" },
    { expect = [[_G.eq(_G.replace_calls[1][3], "%")]], note = "still only this buffer" },
    { lua = "_G.cancel_picker()", note = "cancelled" },
    { lua = "vim.wait(50)" },
    { expect = "_G.eq(_G.text(_G.source), _G.before)", note = "no replacement, no stray declaration" },
    {
      expect = [[not pcall(vim.api.nvim_get_autocmds, { group = "RecommenderNvimReplaceInsert" })]],
      note = "the watcher is gone",
    },

    { lua = "_G.replace_calls = {}" },
    { keys = ":Recommender -r<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "q", note = "closed without a pick" },
    { wait = "#_G.floats() == 0" },
    { expect = "_G.eq(#_G.replace_calls, 0)" },
    { expect = [[not pcall(vim.api.nvim_get_autocmds, { group = "RecommenderNvimReplaceInsert" })]], note = "no watcher armed" },
    { lua = [[vim.cmd("Replace x y %")
      _G.apply("beta.two", "other")]], note = "an unrelated picker, and a change" },
    { lua = "vim.wait(100)" },
    { expect = "_G.eq(vim.api.nvim_buf_line_count(_G.source), #_G.sample())", note = "inserts nothing anywhere" },
  },
  manual = {
    "With the real replacer.nvim and engine = telescope: the prompt appears, a confirmed replace gets the declaration after it, a cancelled one leaves the buffer",
    "The same with engine = fzf",
    "Apply-all (<C-a>) with both engines: Yes inserts the declaration after the replace, No inserts nothing",
    "Replace-and-reopen (<C-r>) on 3+ matches with both engines: no declaration while a picker is open, no skipped match, the declaration once the last one closes",
  },
}
