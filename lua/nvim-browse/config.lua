---@class NvimBrowseConfig
---@field fallback fun(): nil default: A function to call Snacks.gitbrowse
---@field get_commit "curl"|"gh" default: "curl"
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

---@class NvimBrowseOpts
---@field fallback? fun(): nil

---@param opts? NvimBrowseOpts
M.setup = function(opts)
  M = vim.tbl_extend("force", M, opts or {})
end

M.setup()

return M
