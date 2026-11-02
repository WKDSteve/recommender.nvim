---@module 'recommender.float.autocmds'
---Temporary autocmds used by replace-mode to detect when :Replace finishes.
---
---Preferred path: replacer.nvim's public `User ReplacerDone` event (fired once
---when a run is over, with `applied`); the alias is inserted when the run that
---was started for it applied something. The rest of this header describes the
---fallback heuristic for a replacer.nvim without that event.
---
---:Replace (replacer.nvim) opens a picker over the matches; the alias line is
---inserted once that picker's window closes and the target buffer changed.
---Both picker backends of replacer.nvim are recognised by the filetype of the
---closing window's buffer: Telescope's prompt (`TelescopePrompt`) and
---fzf-lua's terminal window (`fzf`). Both close the window *before* running
---the chosen action (the apply), and replace-and-reopen schedules the new
---picker only after that apply, so the change check runs two ticks later.
---replacer's apply-all confirmation (a lib.nvim confirm float, default
---`confirm_all = true`) counts as part of the picker session: the apply only
---runs once it is answered.

local M = {}

local api = vim.api
local autocmd = require("lib.nvim.bindings.autocmd")

---Filetypes of the picker windows :Replace may open, by backend.
---@type table<string, string>
M.PICKER_FILETYPES = {
  TelescopePrompt = "telescope",
  fzf = "fzf-lua",
}

---How long to wait for :Replace to open a picker (or change the buffer)
---before giving up with a notification. ripgrep collects matches
---asynchronously, so the picker does not exist yet when :Replace returns.
M.START_TIMEOUT_MS = 5000

---Generation of the newest watcher: arming a new one supersedes (clears) the
---previous one, whose pending timer must then stay silent.
local current_gen = 0

---@internal
---@param buf integer
---@return boolean
local function is_picker_buf(buf)
  return api.nvim_buf_is_valid(buf) and M.PICKER_FILETYPES[vim.bo[buf].filetype] ~= nil
end

---True when `winid` shows a :Replace picker window (Telescope prompt or fzf-lua).
---@param winid integer
---@return boolean
function M.is_picker_win(winid)
  if not api.nvim_win_is_valid(winid) then
    return false
  end
  return is_picker_buf(api.nvim_win_get_buf(winid))
end

---Filetypes of the other windows a :Replace session may show between the
---picker closing and the apply: replacer's apply-all confirmation.
---@type table<string, true>
local SESSION_FILETYPES = { ["lib-kit-confirm"] = true }

---@internal
---True when `winid` is a picker window or another window of the :Replace
---session (the apply-all confirmation) whose close may precede the apply.
---@param winid integer
---@return boolean
local function is_session_win(winid)
  if not api.nvim_win_is_valid(winid) then
    return false
  end
  local buf = api.nvim_win_get_buf(winid)
  return is_picker_buf(buf) or (api.nvim_buf_is_valid(buf) and SESSION_FILETYPES[vim.bo[buf].filetype] == true)
end

---@internal
---@return boolean
local function any_session_win_open()
  for _, win in ipairs(api.nvim_list_wins()) do
    if is_session_win(win) then
      return true
    end
  end
  return false
end

---@internal
---@param buf integer
---@param snapshot string[]
---@return boolean
local function buf_changed(buf, snapshot)
  local new_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  if #new_lines ~= #snapshot then
    return true
  end
  for i = 1, #snapshot do
    if snapshot[i] ~= new_lines[i] then
      return true
    end
  end
  return false
end

---Arm the one-shot watcher that inserts `alias_text` into `target_win` once
---:Replace's picker (Telescope or fzf-lua) closed and the buffer changed.
---
---- picker closed, buffer changed       -> alias inserted, watcher removed
---- picker closed, buffer unchanged     -> cancelled, watcher removed silently
---- another picker window still open    -> keep watching (replace-and-reopen)
---- apply-all confirmation still open   -> keep watching (applies on "Yes")
---- no picker seen within `start_timeout_ms` and buffer unchanged -> watcher
---  removed and a warning names why nothing was inserted (no matches, or a
---  picker this plugin does not recognise)
---
---This is the fallback for a replacer.nvim without the public run-end signal;
---`M.register_replace_finish` prefers the signal (see `watch_done_signal`).
---@param target_win integer  Window to insert the alias into
---@param buf_snapshot string[]  Buffer lines before :Replace ran
---@param alias_text string  Alias line to insert if the buffer changed
---@param opts? { start_timeout_ms?: integer, on_unrecognised?: fun(msg: string) }
---@return nil
function M.register_replace_heuristic(target_win, buf_snapshot, alias_text, opts)
  opts = opts or {}
  local group = autocmd.group("RecommenderNvimReplaceInsert", true)
  current_gen = current_gen + 1
  local gen = current_gen
  local done = false
  local seen_picker = false

  local function finish()
    done = true
    if gen == current_gen then
      pcall(api.nvim_del_augroup_by_id, group)
    end
  end

  ---Insert the alias when the buffer changed; return whether it did.
  ---@return boolean
  local function insert_if_changed()
    if not api.nvim_win_is_valid(target_win) then
      finish()
      return true
    end
    local buf = api.nvim_win_get_buf(target_win)
    if not api.nvim_buf_is_valid(buf) or not buf_changed(buf, buf_snapshot) then
      return false
    end
    finish()
    api.nvim_set_current_win(target_win)
    api.nvim_put({ alias_text }, "l", false, true)
    return true
  end

  -- A picker window closed: the action (the apply) runs right after the close
  -- in both backends, and replace-and-reopen schedules the next picker only
  -- after that apply. Deciding one tick later would insert the alias before
  -- the reopened picker exists, shift every line below it and make replacer
  -- skip the remaining matches as stale; two ticks later the picker is open.
  local function settle()
    if done or gen ~= current_gen or any_session_win_open() then
      return
    end
    if not insert_if_changed() then
      finish() -- :Replace was cancelled, the buffer is unchanged
    end
  end

  autocmd.create("WinClosed", function(args)
    local winid = tonumber(args.match)
    if done or not winid or not is_session_win(winid) then
      return
    end
    seen_picker = true
    vim.schedule(function()
      vim.schedule(settle)
    end)
  end, { group = group })

  -- fzf-lua sets its filetype once with events ignored, then again normally;
  -- Telescope sets the prompt filetype normally. Either marks the picker seen.
  autocmd.create("FileType", function()
    seen_picker = true
  end, { group = group, pattern = vim.tbl_keys(M.PICKER_FILETYPES) })

  vim.defer_fn(function()
    if done or gen ~= current_gen or seen_picker or any_session_win_open() then
      return
    end
    if insert_if_changed() then
      return -- :Replace applied without a picker
    end
    finish()
    local msg = string.format(
      "replace mode: :Replace opened no picker this plugin recognises (supported: Telescope, fzf-lua) "
        .. "or found no matches -- alias not inserted: %s",
      alias_text
    )
    if opts.on_unrecognised then
      opts.on_unrecognised(msg)
    else
      require("recommender.util.notify").create("[recommender]").warn(msg)
    end
  end, opts.start_timeout_ms or M.START_TIMEOUT_MS)
end

---Name of replacer.nvim's public run-end event (`User ReplacerDone`), or nil
---when the installed replacer.nvim does not publish one.
---@return string|nil
function M.done_event()
  local ok, replacer = pcall(require, "replacer")
  if ok and type(replacer) == "table" and type(replacer.DONE_EVENT) == "string" then
    return replacer.DONE_EVENT
  end
  return nil
end

---@internal
---Signal path: insert the alias when replacer reports that the run it was
---asked for is over and wrote something. No window or tick heuristics, so the
---fzf-lua split, the `<C-f>` filter and every reopen are covered by the
---session end replacer itself decides.
---
---`opts.old` (the searched text handed to :Replace) pins the watcher to its
---own run: an event of an unrelated :Replace is ignored. A watcher whose run
---never reports (a picker replacer cannot observe, e.g. fzf-tmux) stays
---armed only until the next watcher supersedes it.
---@param event string
---@param target_win integer
---@param alias_text string
---@param opts { old?: string }
---@return nil
local function watch_done_signal(event, target_win, alias_text, opts)
  local group = autocmd.group("RecommenderNvimReplaceInsert", true)
  current_gen = current_gen + 1
  local gen = current_gen

  autocmd.create("User", function(args)
    if gen ~= current_gen then
      return
    end
    local data = type(args.data) == "table" and args.data or {}
    if opts.old ~= nil and data.old ~= opts.old then
      return
    end
    pcall(api.nvim_del_augroup_by_id, group)
    if data.applied ~= true or not api.nvim_win_is_valid(target_win) then
      return
    end
    api.nvim_set_current_win(target_win)
    api.nvim_put({ alias_text }, "l", false, true)
  end, { group = group, pattern = event })
end

---Arm the one-shot watcher that inserts `alias_text` into `target_win` once
---the :Replace it is paired with has applied something.
---
---Uses replacer.nvim's public `User ReplacerDone` event when the installed
---replacer has it (or `opts.signal == true`); otherwise falls back to the
---window/tick heuristic of `register_replace_heuristic`. `opts.signal = false`
---forces the heuristic.
---@param target_win integer  Window to insert the alias into
---@param buf_snapshot string[]  Buffer lines before :Replace ran (heuristic path)
---@param alias_text string  Alias line to insert
---@param opts? { start_timeout_ms?: integer, on_unrecognised?: fun(msg: string), signal?: boolean, old?: string }
---@return nil
function M.register_replace_finish(target_win, buf_snapshot, alias_text, opts)
  opts = opts or {}
  local event = opts.signal ~= false and (M.done_event() or (opts.signal and "ReplacerDone")) or nil
  if event then
    return watch_done_signal(event, target_win, alias_text, opts)
  end
  return M.register_replace_heuristic(target_win, buf_snapshot, alias_text, opts)
end

return M
