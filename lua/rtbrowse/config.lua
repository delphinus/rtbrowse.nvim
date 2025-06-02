---@class RtbrowseConfig
---@field fallback fun(): nil default: A function to call Snacks.gitbrowse
---@field get_commit "curl"|"gh"|false default: "curl"
local M = {
  fallback = function()
    if Snacks then
      Snacks.gitbrowse()
    else
      vim.notify("snacks.nvim not found. Specify another `fallback` option.", vim.log.levels.ERROR)
    end
  end,
  get_commit = "curl",
}

---@class RtbrowseOpts
---@field fallback? fun(): nil default: A function to call Snacks.gitbrowse
---@field get_commit? "curl"|"gh"|false default: "curl"

---@param opts? RtbrowseOpts
M.setup = function(opts)
  vim.print { opts = opts }
  M = vim.tbl_extend("force", M, opts or {})
  vim.print { M = M }
  vim.validate("fallback", M.fallback, "function")
  vim.validate("get_commit", M.get_commit, function(v)
    return v == "curl" or v == "gh" or v == false
  end, false, '"curl" or "gh" or false')
end

M.setup()

return M
