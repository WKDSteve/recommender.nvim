-- Live check: invalid options, section 8 and the layout fallback of section 9 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.config-validation",
  feature = "rec.input-errors",
  title = "recommender.nvim: invalid options warn in :checkhealth, fall back to the default and :Recommender still runs",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.sandbox()
      _G.open("t.lua", _G.sample())
      _G.source = vim.api.nvim_get_current_buf()
      -- Each option in a setup() of its own, the report of it read back, the float opened as the checklist asks.
      function _G.health(opts)
        require("recommender").setup(opts)
        vim.cmd("checkhealth recommender")
        local report = _G.text()
        vim.cmd("bwipeout!")
        vim.api.nvim_set_current_buf(_G.source)
        return report
      end]],
    },
    { expect = [[_G.has(_G.health({ threshold = 0 }), "threshold 0 is not an integer >= 1; using default 3")]] },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "4 suggestions")]], note = "behaves as threshold 3" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { expect = [[_G.has(_G.health({ threshold = "3" }), [=[threshold "3" is not an integer >= 1; using default 3]=])]] },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "4 suggestions")]] },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    {
      expect = [[(function()
        local r = _G.health({ cwd_max_files = -1, blacklist = "vim.api" })
        _G.has(r, "cwd_max_files -1 is not an integer >= 0; using default 500")
        _G.has(r, [=[blacklist "vim.api" is not a table; using the default]=])
        return _G.eq(require("recommender.config").get().cwd_max_files, 500)
      end)()]],
      note = "both fall back",
    },
    { lua = [[vim.api.nvim_buf_set_lines(_G.source, 0, 0, false, _G.uses("vim.api.nvim_x", 3))
      vim.cmd("silent write")]] },
    { keys = ":Recommender cwd<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.text(), "vim.api.nvim_x")]], note = "no crash, and vim.api is not blocked" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    {
      expect = [[(function()
        local r = _G.health({ threshhold = 2, analyzer = "regexx" })
        _G.has(r, [=[unknown option "threshhold" (did you mean "threshold"?)]=])
        return _G.has(r, [=[analyzer "regexx" is not a known analyzer; using default "regex"]=])
      end)()]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "Recommender:")]], note = "still runs" },
    { keys = "q" },
    { wait = "#_G.floats() == 0" },
    { expect = [[_G.has(_G.health({ float_layout = "wide" }), "float_layout")]] },
    { expect = [[_G.eq(require("recommender.config").get().float_layout, "detailed")]], note = "wide: detailed" },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.text(), "→ alpha.one (6 hits)")]], note = "and it draws so, no error" },
  },
}
