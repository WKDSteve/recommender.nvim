-- Live check: `:checkhealth recommender` (task recommender.nvim/testblatt-bindings-checkliste; Setup section of
-- ALL/manual-test-checklists/recommender.md).
return {
  id = "rec.health",
  title = "recommender.nvim: :checkhealth names the dependencies, the parser, the layout and :Replace",
  task = "recommender.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("recommender").setup({})]],
    },
    { keys = ":checkhealth recommender<CR>" },
    { wait = [[_G.report("Neovim >= 0.9") ~= ""]], note = "the report is there" },
    { expect = [[_G.has(_G.report("Neovim >= 0.9"), "OK")]] },
    { expect = [[_G.has(_G.report("lib.nvim.bindings.usercmd.composer"), "OK")]], note = "the hard dependency" },
    { expect = [[_G.has(_G.report("ui.kit available"), "OK")]], note = "the float's picker" },
    { expect = [[_G.has(_G.report("Lua Tree-sitter parser found"), "OK")]], note = "the parser this Neovim ships" },
    {
      expect = [[_G.has(_G.report('"javascript" / "python" / "perf" available'), "OK")]],
      note = "without a parser",
    },
    { expect = [[_G.has(_G.report('float_layout = "detailed"'), "OK")]], note = "float_layout echoed" },
    { expect = [[_G.has(_G.report(":Recommender is registered"), "OK")]], note = "the plugin-loaded guard" },
    { expect = [[_G.report("which-key") ~= ""]], note = "which-key is optional, either line" },
    { expect = [[_G.has(_G.report("keymaps enabled"), "OK")]] },
    { expect = [[_G.has(_G.report("lib.nvim found"), "OK")]], note = "notify/map delegate to it" },
    { expect = [[_G.has(_G.report("config: no unknown"), "OK")]], note = "nothing invalid in the config" },
    { expect = [[_G.eq(_G.report("WARNING"), "")]], note = "no warning line" },
    { expect = [[_G.has(_G.report(":Replace command not found"), "falls back")]], note = "no :Replace yet: the fallback" },
    { keys = ":bwipeout!<CR>" },

    { lua = [[vim.api.nvim_create_user_command("Replace", function() end, {})]], note = "replacer.nvim's command" },
    { keys = ":checkhealth recommender<CR>" },
    { wait = [[_G.report(":Replace command found") ~= ""]] },
    { expect = [[_G.has(_G.report(":Replace command found"), "OK")]], note = "replace mode reads OK" },
  },
}
