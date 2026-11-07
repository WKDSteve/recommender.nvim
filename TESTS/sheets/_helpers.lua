-- TESTS/sheets/_helpers.lua -- what the recommender.nvim test sheets need in their child editor. Not a sheet
-- (`testing.sheet` only reads *.sheet.lua); a sheet's first step runs it with `dofile`, the child's cwd is the
-- project root. The directory is in the spec's @cache-inputs, so a change here re-runs the sheets.

vim.opt.shortmess:append("I")
vim.o.swapfile = false
vim.o.hidden = true
-- As in the real config: a leader the checklist's keys can be read with.
vim.g.mapleader = " "

-- The clipboard leaves the machine: a provider that keeps the text in this editor.
_G.clipboard = {}
local function copy(reg)
  return function(lines, regtype)
    _G.clipboard[reg] = { lines, regtype }
  end
end
local function paste(reg)
  return function()
    return _G.clipboard[reg] or { {}, "v" }
  end
end
vim.g.clipboard = {
  name = "sheet",
  copy = { ["+"] = copy("+"), ["*"] = copy("*") },
  paste = { ["+"] = paste("+"), ["*"] = paste("*") },
  cache_enabled = 0,
}

-- Every notification, for the steps that look at the wording.
_G.notes = {}
vim.notify = function(msg)
  _G.notes[#_G.notes + 1] = tostring(msg)
end

---Whether a notification so far holds `text` (plain).
---@param text string
---@return boolean
function _G.noted(text)
  local all = table.concat(_G.notes, "\n")
  if not all:find(text, 1, true) then
    error(("no %s in the notifications: %s"):format(vim.inspect(text), vim.inspect(all)), 0)
  end
  return true
end

---Forget the notifications so far.
function _G.forget()
  _G.notes = {}
end

---`got == want`, or an error that says what came instead (the failure line of the sheet shows it).
---@param got any
---@param want any
---@return boolean
function _G.eq(got, want)
  if got ~= want then
    error(("got %s, wanted %s"):format(vim.inspect(got), vim.inspect(want)), 0)
  end
  return true
end

---`text` holds `part` (plain), or an error that shows the text.
---@param text string
---@param part string
---@return boolean
function _G.has(text, part)
  if not tostring(text):find(part, 1, true) then
    error(("no %s in %s"):format(vim.inspect(part), vim.inspect(text)), 0)
  end
  return true
end

---The lines of a buffer (default the current one) as one string, joined by a newline.
---@param buf integer|nil
---@return string
function _G.text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false), "\n")
end

---The float windows of this tab.
---@return integer[]
function _G.floats()
  return vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative ~= ""
  end, vim.api.nvim_tabpage_list_wins(0))
end

---The suggestion float is open and focused.
---@return boolean
function _G.open_float()
  return vim.api.nvim_win_get_config(0).relative ~= "" and require("ui.kit").chooser.is_open()
end

---The title of the current window, as one string.
---@return string
function _G.title()
  local t = vim.api.nvim_win_get_config(0).title
  if type(t) ~= "table" then
    return tostring(t)
  end
  return table.concat(vim.tbl_map(function(c)
    return c[1]
  end, t))
end

---The chain of the highlighted suggestion.
---@return string|nil
function _G.current()
  local item = require("ui.kit").chooser.current_item()
  return item and item.suggestion.chain
end

---The chains a float shows, by the lines of the float (both layouts start a suggestion with an arrow).
---@return string
function _G.shown()
  local out = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local chain = line:match("→ (%S+) %(")
    if chain then
      out[#out + 1] = chain
    end
  end
  table.sort(out)
  return table.concat(out, " ")
end

---A temp dir (its real path: a runner's temp may be a short name or a link) as the child's cwd, in `_G.root`.
function _G.sandbox()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  _G.root = vim.fs.normalize(vim.uv.fs_realpath(dir))
  vim.fn.chdir(_G.root)
end

---`n` lines that each use `chain` once.
---@param chain string
---@param n integer
---@return string[]
function _G.uses(chain, n)
  local out = {}
  for i = 1, n do
    out[i] = ("local v%d = %s(%d)"):format(i, chain, i)
  end
  return out
end

---The fixture lines: alpha.one 6 times, beta.two 5, gamma.three 4, delta.four 3, each count unique so the order of
---the list (by count) is fixed; no chain shares a line with another.
---@return string[]
function _G.sample()
  return vim
    .iter({ _G.uses("alpha.one", 6), _G.uses("beta.two", 5), _G.uses("gamma.three", 4), _G.uses("delta.four", 3) })
    :flatten()
    :totable()
end

---Write `rel` below the sandbox.
---@param rel string
---@param lines string[]
---@return string path
function _G.write(rel, lines)
  local path = _G.root .. "/" .. rel
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
  return path
end

---Write `rel` below the sandbox and edit it, the cursor on the first line.
---@param rel string
---@param lines string[]
function _G.open(rel, lines)
  vim.cmd("edit! " .. vim.fn.fnameescape(_G.write(rel, lines)))
end

---A normal-mode mapping exists for `lhs` (`maparg()` without a dict is "" for a Lua callback, bound or not).
---@param lhs string
---@return boolean
function _G.bound(lhs)
  return vim.fn.maparg(lhs, "n", false, true).lhs ~= nil
end

---The lines of the current buffer (a `:checkhealth` report) that hold `text`, as one string.
---@param text string
---@return string
function _G.report(text)
  return table.concat(
    vim.tbl_filter(function(l)
      return l:find(text, 1, true) ~= nil
    end, vim.api.nvim_buf_get_lines(0, 0, -1, false)),
    "\n"
  )
end

---Take the read permission of a file away, for real: `chmod` where there is one, an ACL on Windows.
---@param path string
function _G.deny(path)
  if vim.fn.has("win32") == 1 then
    vim.fn.system({ "icacls", path, "/deny", vim.env.USERNAME .. ":R" })
  else
    vim.fn.setfperm(path, "---------")
  end
end

---Give it back, so that the temp dir can go.
---@param path string
function _G.allow(path)
  if vim.fn.has("win32") == 1 then
    vim.fn.system({ "icacls", path, "/remove:d", vim.env.USERNAME })
  else
    vim.fn.setfperm(path, "rw-------")
  end
end

---A stand-in for replacer.nvim's `:Replace`: records its arguments and, as a real one does, opens a picker.
---The picker is a float whose buffer has the filetype of the Telescope prompt. `_G.apply()` makes the change the
---real one would make and closes it, `_G.cancel_picker()` closes it without one.
function _G.fake_replace()
  _G.replace_calls = {}
  vim.api.nvim_create_user_command("Replace", function(o)
    _G.replace_calls[#_G.replace_calls + 1] = o.fargs
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = "TelescopePrompt"
    _G.picker_source = vim.api.nvim_get_current_buf()
    _G.picker = vim.api.nvim_open_win(buf, true, { relative = "editor", row = 1, col = 1, width = 20, height = 1 })
  end, { nargs = "*" })
end

---Close the stand-in's picker with nothing changed.
function _G.cancel_picker()
  vim.api.nvim_win_close(_G.picker, true)
end

---Replace `old` with `new` in the buffer the stand-in was called from, then close its picker, in the order the two
---real backends run them in: the window goes first, the apply follows.
---@param old string
---@param new string
function _G.apply(old, new)
  vim.api.nvim_win_close(_G.picker, true)
  vim.schedule(function()
    local lines = vim.api.nvim_buf_get_lines(_G.picker_source, 0, -1, false)
    for i, l in ipairs(lines) do
      lines[i] = l:gsub(vim.pesc(old), new)
    end
    vim.api.nvim_buf_set_lines(_G.picker_source, 0, -1, false, lines)
  end)
end
