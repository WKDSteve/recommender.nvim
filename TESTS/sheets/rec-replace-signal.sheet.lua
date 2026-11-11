-- Live check: replace mode against the run-end signal of replacer.nvim, the path a current replacer.nvim takes, with a
-- stand-in for it, section 6 (task recommender.nvim/testblatt-bindings-checkliste;
-- ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.replace-signal",
  feature = "rec.replace",
  title = "recommender.nvim: with replacer's ReplacerDone the declaration follows an applied run of its own chain only",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("t.lua", _G.sample())
      _G.source = vim.api.nvim_get_current_buf()
      _G.before = _G.text()
      package.loaded["replacer"] = { DONE_EVENT = "ReplacerDone" }
      _G.replace_calls = {}
      vim.api.nvim_create_user_command("Replace", function(o)
        _G.replace_calls[#_G.replace_calls + 1] = o.fargs
      end, { nargs = "*" })
      function _G.done(old, applied)
        vim.api.nvim_exec_autocmds("User", {
          pattern = "ReplacerDone",
          data = { reason = applied and "applied" or "no_matches", applied = applied, old = old },
        })
      end
      function _G.armed()
        return pcall(vim.api.nvim_get_autocmds, { group = "RecommenderNvimReplaceInsert" })
      end]],
    },
    { keys = ":Recommender -r<CR>" },
    { wait = "_G.open_float()" },
    { keys = "<CR>" },
    { wait = "_G.replace_calls[1] ~= nil" },
    { expect = "_G.armed() and _G.eq(_G.text(_G.source), _G.before)", note = "waiting, nothing inserted" },
    { lua = [[_G.done("something.else", true)]], note = "another run ended" },
    { expect = "_G.armed() and _G.eq(_G.text(_G.source), _G.before)", note = "not this one's business" },
    { lua = [[_G.done("alpha.one", false)]], note = "its own run, cancelled or without a match" },
    { expect = "not _G.armed() and _G.eq(_G.text(_G.source), _G.before)", note = "no declaration, the watcher gone" },

    { keys = ":Recommender -r<CR>" },
    { wait = "_G.open_float()" },
    { keys = "<CR>" },
    { wait = "_G.replace_calls[2] ~= nil" },
    { lua = [[_G.done("alpha.one", true)]], note = "its own run, applied" },
    {
      wait = [[vim.api.nvim_buf_get_lines(_G.source, 0, 1, false)[1] == "local one = alpha.one"]],
      note = "now the declaration",
    },
    { expect = "not _G.armed() and _G.eq(vim.api.nvim_buf_line_count(_G.source), #_G.sample() + 1)", note = "once" },
  },
}
