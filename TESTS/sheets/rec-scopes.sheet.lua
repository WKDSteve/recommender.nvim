-- Live check: `cwd` scope, its progress and the trap of `A`, section 2 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.scopes",
  title = "recommender.nvim: :Recommender cwd aggregates a tree in the background, A lands in the current buffer",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ progress_style = "statusline" })
      _G.sandbox()
      _G.write("a.lua", vim.list_extend(_G.uses("alpha.one", 3), _G.uses("beta.two", 1)))
      _G.write("sub/b.lua", vim.list_extend(_G.uses("alpha.one", 2), _G.uses("beta.two", 2)))
      _G.write(".git/x.lua", _G.uses("zeta.skipped", 9))
      _G.write("node_modules/y.lua", _G.uses("zeta.skipped", 9))
      _G.open("c.lua", { "local x = 1" })
      _G.source = vim.api.nvim_get_current_buf()]],
    },
    {
      lua = [[-- What the scan tells the statusline, and whether the main loop runs meanwhile.
      local sl = require("lib.nvim.progress.styles.statusline")
      local progress = require("lib.nvim.progress")
      local create = progress.create
      _G.styles, _G.bar = {}, {}
      progress.create = function(o)
        _G.styles[#_G.styles + 1] = o.style
        o.delay_ms = 0 -- a handle is invisible for its first 150 ms, longer than this small scan takes
        local h = create(o)
        local update = h.update
        h.update = function(self, u)
          update(self, u)
          vim.list_extend(_G.bar, sl.active())
          _G.first_tick = _G.first_tick or _G.ticks
          _G.last_tick = _G.ticks
        end
        return h
      end
      -- One count per turn of the main loop, whatever the speed of the machine.
      _G.ticks, _G.ticking = 0, true
      local function tick()
        _G.ticks = _G.ticks + 1
        if _G.ticking then
          vim.schedule(tick)
        end
      end
      tick()]],
    },
    { keys = ":Recommender cwd<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { lua = "_G.ticking = false" },
    { expect = [[_G.has(_G.title(), "2 suggestions") and _G.has(_G.title(), "[PROJECT]")]], note = "the scope in the title" },
    {
      expect = [[_G.has(_G.text(), "alpha.one (5 hits)") and _G.has(_G.text(), "beta.two (3 hits)")]],
      note = "counted across both files",
    },
    { expect = [[not _G.text():find("zeta", 1, true)]], note = ".git and node_modules are skipped" },
    { expect = [[_G.eq(_G.styles[1], "statusline")]], note = "progress_style reaches the registry" },
    { expect = [[_G.has(table.concat(_G.bar, "|"), "files")]], note = "the statusline style holds the scan's text" },
    { expect = "_G.last_tick > _G.first_tick", note = "the main loop ran during the scan" },
    { lua = [[_G.a_on_disk = table.concat(vim.fn.readfile(_G.root .. "/a.lua"), "|")]] },
    { keys = "A", note = "from a buffer that uses none of the chains" },
    { wait = "vim.api.nvim_buf_line_count(_G.source) == 3" },
    {
      expect = [[_G.eq(_G.text(_G.source), "local one = alpha.one\nlocal two = beta.two\nlocal x = 1")]],
      note = "the trap: the aliases land in this buffer",
    },
    {
      expect = [[_G.eq(table.concat(vim.fn.readfile(_G.root .. "/a.lua"), "|"), _G.a_on_disk)]],
      note = "where the chains are: nothing",
    },
  },
  manual = { 'With progress_style = "statusline" and the real status line: the scan shows there while it runs' },
}
