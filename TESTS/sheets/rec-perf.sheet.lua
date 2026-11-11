-- Live check: the `perf` analyzer, section 4 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.perf",
  feature = "rec.perf",
  title = "recommender.nvim: perf flags the four patterns, not the positional insert, and only ever inserts a comment",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})
      _G.sandbox()
      _G.lines = {
        "local t, s = {}, ''",
        "for i = 1, 3 do",
        "  table.insert(t, i)",
        "  table.insert(t, i * 2)",
        "  table.insert(t, 1, i)",
        "  s = s .. 'x'",
        "  local f = string.format('%d', i)",
        "end",
        "for _, v in ipairs(t) do",
        "  print(v)",
        "end",
      }
      _G.open("p.lua", _G.lines)
      _G.source = vim.api.nvim_get_current_buf()
      _G.before = _G.text()]],
    },
    { keys = ":Recommender perf 1<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { expect = [[_G.has(_G.title(), "4 suggestions")]], note = "the four patterns" },
    { expect = [[_G.has(_G.text(), "table.insert(...) (2 hits)")]], note = "the two appends, not the positional insert" },
    { expect = [[_G.has(_G.text(), "ipairs(...) (1 hits)")]] },
    { expect = [[_G.has(_G.text(), "x = x .. y (concat accumulator) (1 hits)")]] },
    { expect = [[_G.has(_G.text(), "string.format(...) (1 hits)")]] },
    {
      expect = [[_G.has(_G.text(), "only a plain join is equivalent (not %5.2f or many operands)")]],
      note = "the tip names its limit",
    },
    { keys = "<CR>", note = "Enter" },
    { wait = "vim.api.nvim_buf_line_count(_G.source) == #_G.lines + 1" },
    { expect = [[_G.has(vim.api.nvim_buf_get_lines(_G.source, 0, 1, false)[1], "-- perf: ")]], note = "a comment at the cursor" },
    {
      expect = [[_G.eq(table.concat(vim.api.nvim_buf_get_lines(_G.source, 1, -1, false), "\n"), _G.before)]],
      note = "nothing else changed",
    },
    { keys = "u" },
    { keys = ":Recommender perf 1<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { keys = "A" },
    { wait = "vim.api.nvim_buf_line_count(_G.source) == #_G.lines + 4" },
    {
      expect = [[(function()
        local l = vim.api.nvim_buf_get_lines(_G.source, 0, 4, false)
        for _, line in ipairs(l) do
          _G.has(line, "-- perf: ")
        end
        return _G.eq(table.concat(vim.api.nvim_buf_get_lines(_G.source, 4, -1, false), "\n"), _G.before)
      end)()]],
      note = "A: four comments, the code as it was",
    },

    {
      lua = [==[_G.forget()
      _G.open("q.lua", {
        "local t = {}",
        "for i = 1, 3 do",
        "  --[[",
        "  table.insert(t, i)",
        "  ]]",
        "  -- table.insert(t, i)",
        "  local s = 'table.insert(t, i)'",
        "end",
        "--[[",
        "for _, v in ipairs(t) do",
        "end",
        "]]",
      })]==],
      note = "the patterns only in comments and a string",
    },
    { keys = ":Recommender perf 1<CR>" },
    { wait = "_G.open_float()" },
    {
      expect = [[_G.has(_G.text(), "table.insert(...) (3 hits)") and _G.has(_G.text(), "ipairs(...) (1 hits)")]],
      note = "the documented limit of a line-based tracker: it misfires in comments and strings",
    },
  },
}
