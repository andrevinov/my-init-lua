------------------------------------------------------------
-- Smart Quit + NvimTree -----------------------------------
------------------------------------------------------------
--
-- O Smart Quit principal transforma :q em :Q para fechar buffers
-- de arquivo sem derrubar o Neovim. Isso é exatamente o que queremos
-- enquanto ainda existe um arquivo real aberto.
--
-- Há, porém, um estado final específico em que queremos sair de vez:
-- somente o buffer vazio de apoio + o NvimTree estão visíveis.
-- Nesse caso, o :q digitado pelo usuário vira :qa.
--
-- Resultado:
--   arquivo + NvimTree   -> :q fecha somente o arquivo
--   vazio   + NvimTree   -> :q fecha o Neovim inteiro
--

local function is_empty_support_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  local buftype = vim.bo[bufnr].buftype

  if buftype ~= "" and buftype ~= "nofile" then
    return false
  end

  if vim.api.nvim_buf_get_name(bufnr) ~= "" then
    return false
  end

  if vim.bo[bufnr].modified then
    return false
  end

  if vim.api.nvim_buf_line_count(bufnr) ~= 1 then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
  return (lines[1] or "") == ""
end

local function is_nvimtree_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.bo[bufnr].filetype == "NvimTree"
end

local function normal_windows_in_current_tab()
  local windows = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)

      -- Ignora floats de Telescope, completion etc.
      if config.relative == "" then
        table.insert(windows, win)
      end
    end
  end

  return windows
end

local function has_other_real_file_buffers()
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local bufnr = info.bufnr

    if vim.api.nvim_buf_is_valid(bufnr)
        and vim.api.nvim_buf_is_loaded(bufnr)
        and vim.bo[bufnr].buftype == ""
        and vim.api.nvim_buf_get_name(bufnr) ~= "" then
      return true
    end
  end

  return false
end

local function only_empty_buffer_and_nvimtree()
  if vim.fn.tabpagenr("$") ~= 1 then
    return false
  end

  if has_other_real_file_buffers() then
    return false
  end

  local windows = normal_windows_in_current_tab()

  if #windows ~= 2 then
    return false
  end

  local first = vim.api.nvim_win_get_buf(windows[1])
  local second = vim.api.nvim_win_get_buf(windows[2])

  return (
    is_empty_support_buffer(first)
    and is_nvimtree_buffer(second)
  ) or (
    is_nvimtree_buffer(first)
    and is_empty_support_buffer(second)
  )
end

function _G.SmartQuitNvimTreeCommand(force)
  if only_empty_buffer_and_nvimtree() then
    return force and "qa!" or "qa"
  end

  return force and "Q!" or "Q"
end

-- Sobrescreve apenas as abreviações de :q / :q! criadas pelo Smart Quit.
-- O comando :Q em si continua sendo o mesmo definido no init.lua.
vim.cmd([[
  cnoreabbrev <expr> q
        \ (getcmdtype()==':' && getcmdline() ==# 'q')
        \ ? v:lua.SmartQuitNvimTreeCommand(v:false)
        \ : 'q'

  cnoreabbrev <expr> q!
        \ (getcmdtype()==':' && getcmdline() ==# 'q!')
        \ ? v:lua.SmartQuitNvimTreeCommand(v:true)
        \ : 'q!'
]])
