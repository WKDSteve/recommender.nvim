-- Live check: a file without read permission, section 2 (task recommender.nvim/testblatt-bindings-checkliste;
-- ALL/manual-test-checklists/recommender.md). The permission is really taken away. An elevated Windows account reads
-- the file all the same (libuv opens with backup semantics, the GitHub runner has the privilege): there it is a skip.
return {
  id = "rec.scope-unreadable",
  title = "recommender.nvim: a file without read permission is said, in cfile and in a path scan",
  task = "recommender.nvim/manual-checklist-run",
  requires = {
    {
      lua = [[(function()
        dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
        return _G.can_deny()
      end)()]],
      reason = "this account reads a file it has no read permission for (an elevated Windows account)",
    },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.open("c.lua", { "secret.lua" })
      _G.secret = _G.write("secret.lua", _G.uses("alpha.one", 5))
      _G.deny(_G.secret)]],
      note = "the real permission taken away",
    },
    { keys = ":Recommender cfile<CR>" },
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
