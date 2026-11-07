-- Live check: the file cap of a tree scan at its default, section 2 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.scope-cap",
  title = "recommender.nvim: more than 500 files: the scan warns and reads 500",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      for i = 1, 501 do
        vim.fn.writefile({ "local v = alpha.one(1)" }, _G.root .. "/f" .. i .. ".lua")
      end]],
    },
    { keys = ":Recommender cwd<CR>" },
    { wait = "_G.open_float()", timeout = 20000 },
    { expect = [[_G.noted("cwd scan capped at 500 files (config.cwd_max_files)")]] },
    { expect = [[_G.has(_G.text(), "alpha.one (500 hits)")]], note = "exactly the cap" },
  },
}
