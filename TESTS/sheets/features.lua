-- TESTS/sheets/features.lua -- the functionalities of recommender.nvim as its user meets them; `testing sheets report`
-- says which ones have a feature sheet (`feature = "<id>"`) and in which state, and K16 warns about a sheet that names
-- an id not listed here. Data: read with an empty environment like a sheet (testing.nvim docs/SHEETS.md).
-- The list follows docs/FEATURES.md and ALL/manual-test-checklists/recommender.md.
return {
  {
    id = "rec.float",
    title = ":Recommender opens a float of the chains worth an alias; Enter or A inserts the declaration, y yanks it",
    surface = { "command:Recommender", "binding:<leader>lr" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.analyzers",
    title = "Lua through a regex or Tree-sitter, JavaScript/TypeScript and Python each have their own backend",
    surface = { "config:analyzer" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.perf",
    title = 'analyzer = "perf" flags four benchmarked Lua anti-patterns and only ever inserts a comment',
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.threshold",
    title = "The threshold is given positionally, as --threshold=N, -t or as a count before the key",
    surface = { "config:threshold" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.scopes",
    title = "Besides the buffer, a line, the file under the cursor, its directory or the whole tree is scanned",
    surface = { "config:cwd_ignore", "config:cwd_max_files" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.replace",
    title = "With -r an accepted suggestion also rewrites every occurrence in the buffer through :Replace",
    surface = { "binding:<leader>lR" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.ignore",
    title = "Backspace hides a suggestion in this buffer only, U brings it back",
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.blacklist-aliases",
    title = "A prefix blacklist keeps chains out, and a custom alias map names the declaration",
    surface = { "config:blacklist", "config:custom_aliases" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.layout",
    title = 'float_layout = "compact" shows one line per suggestion instead of the detailed view',
    surface = { "config:float_layout" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.keymaps",
    title = "The default keys run :Recommender with their analyzer or mode; keymaps moves or drops them",
    surface = { "config:keymaps" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.float-keys",
    title = "The keys inside the float are moved or switched off with float_keymaps, and its help lists what is bound",
    surface = { "config:float_keymaps" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "rec.statusline",
    title = "A statusline component counts the suggestions of the buffer and follows edits",
    docs = "docs/statusline.md",
  },
  {
    id = "rec.input-errors",
    title = "A typo in an argument or an invalid option is reported, runs nothing wrong, and the default applies",
    docs = "docs/troubleshooting.md",
  },
  {
    id = "rec.progress",
    title = "A path or cwd scan runs in the background and shows its progress as progress_style says",
    surface = { "config:progress_style" },
    docs = "docs/FEATURES.md",
  },
}
