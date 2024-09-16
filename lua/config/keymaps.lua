-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Disabled lazyvim keymaps
vim.keymap.del("n", "<C-Right>")
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-/>")
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<leader>fT")

-- Add any additional keymaps here
-- Chetra custom keymaps
vim.keymap.set("n", "<A-->", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<A-=>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<A-<>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<A->>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
