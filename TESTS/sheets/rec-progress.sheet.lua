-- Live check: progress_style = "notify" over a `cwd` scan and an empty `path` scan (docs/FEATURES.md, the scopes;
-- docs/configuration.md, async cwd/path scanning). rec.scopes covers the "statusline" style.
return {
  id = "rec.progress",
  feature = "rec.progress",
  title = 'recommender.nvim: with progress_style = "notify" a scan reports its progress and its end as notifications',
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ progress_style = "notify" })
      _G.sandbox()
      _G.write("a.lua", _G.uses("alpha.one", 3))
      _G.write("sub/b.lua", _G.uses("alpha.one", 2))
      _G.write("empty/notes.txt", { "no Lua here" })
      _G.open("c.lua", { "local x = 1" })
      -- A handle is invisible for its first 150 ms, longer than this small scan takes: show it at once.
      local progress = require("lib.nvim.progress")
      local create = progress.create
      _G.styles = {}
      progress.create = function(o)
        _G.styles[#_G.styles + 1] = o.style
        o.delay_ms = 0
        return create(o)
      end]],
    },
    { keys = ":Recommender cwd<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.eq(_G.styles[1], "notify")]], note = "progress_style reaches the registry" },
    { expect = [[_G.noted("[recommender] scanning directories")]], note = "the walk is announced" },
    { expect = [[_G.noted("[recommender] scanned 3 files")]], note = "the end says how many files were read" },
    { expect = [[_G.has(_G.text(), "alpha.one (5 hits)")]], note = "and the float shows what they hold" },
    { keys = "q" },
    { wait = "not _G.open_float()" },
    { lua = [[_G.forget()
      vim.cmd("edit! " .. vim.fn.fnameescape(_G.root .. "/empty/notes.txt"))]] },
    { keys = ":Recommender path<CR>" },
    { wait = [[table.concat(_G.notes, "|"):find("No matching files found", 1, true) ~= nil]], timeout = 5000 },
    { expect = [[_G.noted("[recommender] no matching files found")]], note = "the indicator ends as cancelled" },
    { expect = "not _G.open_float()", note = "and no float opens" },
  },
}
