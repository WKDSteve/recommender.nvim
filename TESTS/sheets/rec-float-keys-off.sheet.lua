-- Live check: `float_keymaps = false`, section 10 (task recommender.nvim/testblatt-bindings-checkliste; ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.float-keys-off",
  feature = "rec.float-keys",
  title = "recommender.nvim: float_keymaps = false: y, A, Backspace, U do nothing, j and k still move",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({ float_keymaps = false })
      _G.sandbox()
      _G.open("t.lua", _G.sample())
      _G.source = vim.api.nvim_get_current_buf()
      _G.before = _G.text()]],
    },
    { keys = ":Recommender<CR>" },
    { wait = "_G.open_float()", timeout = 5000 },
    { lua = "_G.forget()" },
    { expect = [[_G.eq(vim.fn.maparg("y", "n", false, true).buffer, nil)]], note = "y is not the plugin's" },
    { keys = "y", ignore_errmsg = true },
    { expect = [[_G.eq(vim.fn.getreg("+"), "")]], note = "nothing on the clipboard" },
    { keys = "A", ignore_errmsg = true },
    { keys = "<BS>", ignore_errmsg = true },
    { keys = "U", ignore_errmsg = true },
    { settle = 2000 },
    { expect = "_G.open_float() and _G.eq(_G.text(_G.source), _G.before)", note = "no insert, the float open" },
    { expect = [[_G.eq(_G.shown(), "alpha.one beta.two delta.four gamma.three")]], note = "nothing ignored" },
    -- The extra actions go, the way through the list stays: j and k are the chooser's, by suggestion.
    { lua = [[_G.first, _G.row = _G.current(), vim.fn.line(".")]] },
    { keys = "j" },
    {
      expect = [[_G.current() ~= _G.first and _G.eq(vim.fn.line("."), _G.row + 3)]],
      note = "j: the next suggestion",
    },
    { keys = "k" },
    { expect = [[_G.eq(_G.current(), _G.first) and _G.eq(vim.fn.line("."), _G.row)]], note = "k: back" },
  },
}
