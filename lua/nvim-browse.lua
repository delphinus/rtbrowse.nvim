local function open()
local filename=vim.api.nvim_buf_get_name(0)
end

return {open=open}
