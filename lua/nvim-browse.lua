local runtime_re = vim.pesc(vim.env.VIMRUNTIME) .. "/(.*)"
local fallback = function()
  if Snacks then
    Snacks.gitbrowse()
  else
    vim.notify("snacks.nvim not found. Specify another `fallback` option", vim.log.levels.WARN)
  end
end

---@return { hash?: string, version?: string }
local function nvim_revision()
  local result = vim.api.nvim_exec2("version", { output = true })
  -- ex: NVIM v0.12.0-dev-5606+gcc78f88201-Homebrew
  local hash = result.output:match "NVIM v%d+%.%d+%.%d+%-%S+g([0-9a-f]+)"
  return hash and { hash = hash } or { version = (result.output:match "NVIM (v%d+%.%d+%.%d+)") }
end

---@param cmd string[]
---@param opts? vim.SystemOpts
---@param on_exit? fun(out: vim.SystemCompleted): nil
local function system(cmd, opts, on_exit)
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

---@param rev string
---@param path string
---@param start number
---@param finish number
local function open_url(rev, path, start, finish)
  vim.ui.open(("https://github.com/neovim/neovim/blob/%s/runtime/%s#L%d-L%d"):format(rev, path, start, finish))
end

---@return string?
local function runtime_path()
  local filename = vim.api.nvim_buf_get_name(0)
  return (filename:match(runtime_re))
end

---@param filepath? string
local function open(filepath)
  if not filepath then
    vim.notify("this is not a file in $VIMRUNTIME", vim.log.levels.DEBUG)
    return
  end
  local start, finish
  if vim.fn.mode():find "[vV]" then
    vim.fn.feedkeys(":", "nx")
    local s = vim.api.nvim_buf_get_mark(0, "<")[1]
    local f = vim.api.nvim_buf_get_mark(0, ">")[1]
    vim.fn.feedkeys("gv", "nx")
    start = s > f and s or f
    finish = s > f and f or s
  else
    start = vim.fn.line "."
    finish = start
  end
  local rev = nvim_revision()
  if rev.version then
    open_url(rev.version, filepath, start, finish)
  else
    system({ "curl", "https://api.github.com/repos/neovim/neovim/commits/" .. rev.hash }, nil, function(out)
      local sha = vim.json.decode(out.stdout).sha
      if sha then
        open_url(sha, filepath, start, finish)
      else
        system({ "gh", "api", "/repos/neovim/neovim/commits/" .. rev.hash }, nil, function(out)
          local sha = vim.json.decode(out.stdout).sha
          if sha then
            open_url(sha, filepath, start, finish)
          else
            vim.notify("failed to fetch with curl and gh", vim.log.levels.ERROR)
          end
        end)
      end
    end)
  end
end

local function browse()
  local filepath = runtime_path()
  if filepath then
    open(filepath)
  else
    fallback()
  end
end

return { browse = browse, open = open }
