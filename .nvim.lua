local reload = function ()
    local cmd = "curl -X POST http://localhost:3636/action/reload"
    print(cmd)
    vim.fn.system(cmd)
end

vim.api.nvim_create_augroup("bubbl", {})
vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.lua",
    group = "bubbl",
    callback = function() vim.defer_fn(reload, 0) end,
})

vim.api.nvim_create_autocmd("FileType", { pattern = "lua", command = "setlocal makeprg=./bubbl" })
vim.api.nvim_create_autocmd("FileType", { pattern = "c", command = "setlocal makeprg=./build.lua" })
