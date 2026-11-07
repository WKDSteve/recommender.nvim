-- .testing.lua -- configuration of testing.nvim for this project.
-- Written by `testing migrate`; edit freely (it is never overwritten). Every key is optional; the
-- keys are documented in testing.nvim's docs/CONFIG.md. Loading this file executes it (same trust
-- as running the specs).
return {
  -- Lua module root of the project.
  plugin = "recommender",
  -- How the spec files are run: "auto" = sniffed per file, "h" = on the project's own TESTS/harness.lua,
  -- "script" = a self-running script in its own process.
  dialect = { ["TESTS/sheets_spec.lua"] = "busted", ["*"] = "h" },
  -- Dependencies (directory names) put on the runtimepath: $<NAME>_DIR, .deps/<name>, ../<name>,
  -- stdpath('data')/lazy/<name>.
  deps = { "lib.nvim", "ui.nvim" },
  -- "none" = all specs in one nvim, "file" = one nvim per spec file
  -- (nothing leaks from one file into the next).
  isolated = "none",
  -- All test sheets run in one spec file, one child editor each: the defaults of 10 s per case and 60 s per
  -- file are reached under load (fileops, 2026-11-07).
  timeouts = { case_ms = 30000, file_ms = 300000 },
  -- Guards (docs/GUARDS.md of testing.nvim): every guard errors.
  guards = {
    fs = "error",
    scheduled_error = "error",
    prompt = "error",
    deprecation = "error",
    process_net = "error",
    -- error: the suite leaves no state behind. Each spec wipes the buffers it creates, deletes the
    -- keymaps, autocmd groups and :Recommender user command it brings in, and restores options.
    -- isolated stays "none" for speed (about 1.6 s against 7.5 s); the suite is green with "file" too.
    state = "error",
  },
  guard_allow = {
    fs = {
      -- project_spec.lua creates and deletes this fixture tree inside the repository.
      "TESTS/.fixture",
      -- usrcmds_spec.lua creates and deletes this fixture tree inside the repository.
      "TESTS/.fixture_usrcmds",
      -- plugin/recommender_autodoc.lua writes the helptags when doc/tags is missing (a fresh clone).
      "doc",
    },
    -- sheets_spec.lua: every test sheet (TESTS/sheets/) runs in a child editor.
    spawn = { "nvim" },
  },
  -- gated: a failed conformance check makes `scripts/test.sh conformance` exit 1 (docs/CONFORMANCE.md of testing.nvim)
  conformance = { gate = true },
}
