-- Live check: what `cfile` says about a missing file name and a missing file, section 2 (task
-- recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.scope-errors",
  title = "recommender.nvim: no file name under the cursor, no such file: said, no float",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("c.lua", { "", "foo_no_such_file.lua" })]],
    },
    { keys = ":Recommender cfile<CR>", note = "on an empty line" },
    { wait = [[_G.noted("no file name under the cursor")]] },
    { expect = "#_G.floats() == 0" },
    { keys = "j:Recommender cfile<CR>", note = "a word that names no file" },
    { wait = [[_G.noted('no readable file found for "foo_no_such_file.lua" under the cursor')]] },
    { expect = "#_G.floats() == 0" },
  },
}
