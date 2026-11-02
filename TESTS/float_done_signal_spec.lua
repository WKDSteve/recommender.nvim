-- TESTS/float_done_signal_spec.lua — recommender.float.autocmds, signal path:
-- the replace-mode alias is inserted when replacer.nvim reports `User
-- ReplacerDone` for the run that was started for it (no picker windows, no
-- tick heuristics). replacer.nvim itself is not a dependency: the event is
-- fired by hand, as replacer would.

return function(H)
  local fa = require("recommender.float.autocmds")
  local api = vim.api
  local GROUP = "RecommenderNvimReplaceInsert"

  local created = {} ---@type integer[]
  ---@param lines string[]
  ---@return integer win, integer buf
  local function target(lines)
    local buf = api.nvim_create_buf(false, true)
    created[#created + 1] = buf
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local win = api.nvim_get_current_win()
    api.nvim_win_set_buf(win, buf)
    return win, buf
  end

  local function armed()
    return pcall(api.nvim_get_autocmds, { group = GROUP }) and #api.nvim_get_autocmds({ group = GROUP }) > 0
  end

  ---@param data table
  local function fire(data)
    api.nvim_exec_autocmds("User", { pattern = "ReplacerDone", modeline = false, data = data })
  end

  local function lines_of(buf)
    return table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), "|")
  end

  -- An applied run of our own :Replace inserts the alias once ----------------
  do
    local win, buf = target({ "a", "b" })
    fa.register_replace_finish(win, {}, "local x = vim.x", { signal = true, old = "vim.x" })
    H.ok(armed(), "signal: the watcher is armed")
    fire({ reason = "applied", applied = true, files = 1, spots = 2, old = "vim.x", new = "x" })
    H.eq(lines_of(buf), "local x = vim.x|a|b", "signal: an applied run inserts the alias")
    H.falsy(armed(), "signal: the watcher is removed after the insert")
    fire({ reason = "applied", applied = true, files = 1, spots = 1, old = "vim.x", new = "x" })
    H.eq(lines_of(buf), "local x = vim.x|a|b", "signal: a later event inserts nothing more")
  end

  -- A cancelled or empty run inserts nothing and disarms --------------------
  for _, reason in ipairs({ "cancelled", "no_matches", "no_picker", "error" }) do
    local win, buf = target({ "a" })
    fa.register_replace_finish(win, {}, "ALIAS", { signal = true, old = "q" })
    fire({ reason = reason, applied = false, files = 0, spots = 0, old = "q", new = "z" })
    H.eq(lines_of(buf), "a", "signal: " .. reason .. " inserts nothing")
    H.falsy(armed(), "signal: " .. reason .. " removes the watcher")
  end

  -- An event of an unrelated :Replace is ignored ------------------------------
  do
    local win, buf = target({ "a" })
    fa.register_replace_finish(win, {}, "ALIAS", { signal = true, old = "mine" })
    fire({ reason = "applied", applied = true, files = 1, spots = 1, old = "other", new = "z" })
    H.eq(lines_of(buf), "a", "signal: another run's event does not insert")
    H.ok(armed(), "signal: and the watcher keeps waiting for its own run")
    fire({ reason = "applied", applied = true, files = 1, spots = 1, old = "mine", new = "z" })
    H.eq(lines_of(buf), "ALIAS|a", "signal: its own run's event inserts")
  end

  -- Re-arming supersedes the previous watcher ---------------------------------
  do
    local win, buf = target({ "a" })
    fa.register_replace_finish(win, {}, "OLD", { signal = true, old = "q" })
    fa.register_replace_finish(win, {}, "NEW", { signal = true, old = "q" })
    fire({ reason = "applied", applied = true, files = 1, spots = 1, old = "q", new = "z" })
    H.eq(lines_of(buf), "NEW|a", "signal: only the newest watcher inserts")
  end

  -- Target window gone: nothing raised, nothing inserted ----------------------
  do
    vim.cmd("silent! only")
    local buf = api.nvim_create_buf(false, true)
    created[#created + 1] = buf
    local win = api.nvim_open_win(buf, false, { relative = "editor", row = 0, col = 0, width = 5, height = 1 })
    fa.register_replace_finish(win, {}, "ALIAS", { signal = true, old = "q" })
    api.nvim_win_close(win, true)
    local ok = pcall(fire, { reason = "applied", applied = true, files = 1, spots = 1, old = "q", new = "z" })
    H.ok(ok, "signal: a vanished target window does not raise")
    H.falsy(armed(), "signal: and the watcher is removed")
  end

  -- Without replacer.nvim's event the heuristic path is used -------------------
  do
    H.eq(fa.done_event(), nil, "no replacer.nvim on the path: no signal")
    local win, buf = target({ "a" })
    fa.register_replace_finish(win, { "a" }, "ALIAS", { start_timeout_ms = 20, on_unrecognised = function() end })
    H.ok(armed(), "fallback: the heuristic watcher is armed")
    fire({ reason = "applied", applied = true, files = 1, spots = 1, old = "q", new = "z" })
    H.eq(lines_of(buf), "a", "fallback: the event is ignored by the heuristic watcher")
    vim.wait(80, function()
      return false
    end, 5)
    H.falsy(armed(), "fallback: the start timeout disarmed it")
  end

  for _, buf in ipairs(created) do
    pcall(api.nvim_buf_delete, buf, { force = true })
  end
end
