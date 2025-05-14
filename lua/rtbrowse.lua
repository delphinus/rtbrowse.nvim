local config = require "rtbrowse.config"

---@class Rtbrowse
local M = {
  runtime_re = vim.pesc(vim.env.VIMRUNTIME) .. "/(.*)",
}

---@param cmd string[]
---@param opts? vim.SystemOpts
---@param on_exit? fun(out: vim.SystemCompleted): nil
function M.system(cmd, opts, on_exit)
  local timer = vim.uv.new_timer()
  assert(timer)
  local ok, job = pcall(vim.system, cmd, opts, function(out)
    timer:stop()
    if on_exit then
      on_exit(out)
    end
  end)
  if not ok then
    vim.notify("failed to spawn " .. cmd[1], vim.log.levels.ERROR)
    return
  end
  timer:start(5000, 0, function()
    if not job:is_closing() then
      job:kill(9)
    end
  end)
end

---@param filepath string
function M.open(filepath)
  local start, finish = M.get_lines()
  local function open_url(rev)
    vim.ui.open(("https://github.com/neovim/neovim/blob/%s/runtime/%s#L%d-L%d"):format(rev, filepath, start, finish))
  end
  local revision = M.get_revision()
  if revision.version then
    open_url(revision.version)
  elseif config.get_commit == "curl" then
    M.get_commit({ "curl", "https://api.github.com/repos/neovim/neovim/commits/" .. revision.hash }, open_url)
  else
    M.get_commit({ "gh", "api", "/repos/neovim/neovim/commits/" .. revision.hash }, open_url)
  end
end

---@param cmd string[]
---@param cb fun(rev: string): nil
function M.get_commit(cmd, cb)
  M.system(cmd, nil, function(out)
    local ok, json = pcall(vim.json.decode, out.stdout)
    if not ok then
      vim.notify("failed to decode response: " .. table.concat(cmd, " "), vim.log.levels.ERROR)
      return
    end
    local sha = json.sha
    if not sha then
      vim.notify("cannot found SHA: " .. table.concat(cmd, " "), vim.log.levels.ERROR)
      return
    end
    cb(sha)
  end)
end

---@return number, number
function M.get_lines()
  if vim.fn.mode():find "[vV]" then
    vim.fn.feedkeys(":", "nx")
    local start = vim.api.nvim_buf_get_mark(0, "<")[1]
    local finish = vim.api.nvim_buf_get_mark(0, ">")[1]
    vim.fn.feedkeys("gv", "nx")
    if start > finish then
      return start, finish
    end
    return finish, start
  end
  local start = vim.fn.line "."
  return start, start
end

---@return { hash?: string, version?: string }
function M.get_revision()
  local result = vim.api.nvim_exec2("version", { output = true })
  -- ex: NVIM v0.12.0-dev-5606+gcc78f88201-Homebrew
  local hash = result.output:match "NVIM v%d+%.%d+%.%d+%-%S+g([0-9a-f]+)"
  return hash and { hash = hash } or { version = (result.output:match "NVIM (v%d+%.%d+%.%d+)") }
end

function M.browse()
  local filename = vim.api.nvim_buf_get_name(0)
  local filepath = (filename:match(M.runtime_re))
  if filepath then
    M.open(filepath)
  else
    config.fallback()
  end
end

return M
