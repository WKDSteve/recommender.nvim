-- Live check: what `cfile` and `path` say about missing and unreadable files, section 2 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.scope-errors",
  title = "recommender.nvim: no file name, no such file, a file without read permission: said, not hidden",
  task = "recommender.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("c.lua", { "", "foo_no_such_file.lua", "secret.lua" })]],
    },
    { keys = ":Recommender cfile<CR>", note = "on an empty line" },
    { wait = [[_G.noted("no file name under the cursor")]] },
    { expect = "#_G.floats() == 0" },
    { keys = "j:Recommender cfile<CR>", note = "a word that names no file" },
    { wait = [[_G.noted('no readable file found for "foo_no_such_file.lua" under the cursor')]] },
    { expect = "#_G.floats() == 0" },

    {
      lua = [[_G.secret = _G.write("secret.lua", _G.uses("alpha.one", 5))
      _G.deny(_G.secret)
      _G.forget()]],
      note = "the real permission taken away",
    },
    { keys = "j:Recommender cfile<CR>" },
    {
      wait = [[(function()
        local all = table.concat(_G.notes, "|")
        return all:find("no readable file found", 1, true) or all:find("1 file could not be read", 1, true)
      end)()]],
      note = "either error, never a plain No suggestions",
    },
    { expect = "#_G.floats() == 0" },

    {
      lua = [[vim.fn.delete(_G.root .. "/c.lua")
      _G.forget()
      _G.progress = {}
      local progress = require("lib.nvim.progress")
      local create = progress.create
      progress.create = function(o)
        local h = create(o)
        local finish = h.finish
        h.finish = function(self, t)
          _G.progress[#_G.progress + 1] = t
          finish(self, t)
        end
        return h
      end]],
    },
    { keys = ":Recommender path<CR>", note = "a directory with only that file" },
    { wait = [[_G.noted("No suggestions (threshold: 3) — 1 file could not be read")]], timeout = 5000 },
    { expect = [[_G.has(table.concat(_G.progress, "|"), "(1 unreadable)")]], note = "the finish text says so too" },
    { lua = "_G.allow(_G.secret)", note = "so that the temp dir can go" },
  },
}
