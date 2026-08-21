------------------------------------------------------------
-- Codex side panel ----------------------------------------
------------------------------------------------------------
local codex_panel = {
  buf = 0,
  win = 0,
  job = 0,
  prev_win = 0,
}

local function valid_win(win)
  return win ~= 0 and vim.api.nvim_win_is_valid(win)
end

local function valid_buf(buf)
  return buf ~= 0 and vim.api.nvim_buf_is_valid(buf)
end

local function hide_codex_window()
  local panel_win = codex_panel.win

  if not valid_win(panel_win) then
    codex_panel.win = 0
    return false
  end

  local current_win = vim.api.nvim_get_current_win()
  local return_win = codex_panel.prev_win
  local ok = pcall(vim.api.nvim_win_hide, panel_win)

  if not ok then
    return false
  end

  codex_panel.win = 0

  if current_win == panel_win and valid_win(return_win) then
    vim.api.nvim_set_current_win(return_win)
  end

  return true
end

function _G.CodexToggle(width)
  local current_tab = vim.api.nvim_get_current_tabpage()

  -- Se o painel já está aberto nesta tab, só esconde.
  if valid_win(codex_panel.win) then
    local panel_tab = vim.api.nvim_win_get_tabpage(codex_panel.win)

    if panel_tab == current_tab then
      hide_codex_window()
      return
    end

    -- Se estava aberto em outra tab, esconde lá e abre nesta.
    hide_codex_window()
  end

  codex_panel.prev_win = vim.api.nvim_get_current_win()

  -- Cria uma split vertical sempre na extrema direita.
  -- O vsplit nasce mostrando o mesmo buffer da janela principal;
  -- por isso o terminal do Codex recebe um buffer próprio logo abaixo.
  vim.cmd('botright vsplit')
  codex_panel.win = vim.api.nvim_get_current_win()

  if valid_buf(codex_panel.buf) then
    -- Reusa o mesmo terminal/Codex ao reabrir o painel.
    vim.api.nvim_set_current_buf(codex_panel.buf)
  else
    -- Primeiro uso: cria um buffer exclusivo para o painel.
    -- Assim o termopen() não transforma também o buffer da janela principal.
    codex_panel.buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(codex_panel.buf)

    codex_panel.job = vim.fn.termopen(vim.o.shell, {
      detach = 0,
      cwd = vim.fn.getcwd(),
    })

    -- Não polui :ls nem Telescope buffers e sobrevive ao toggle.
    vim.bo[codex_panel.buf].buflisted = false
    vim.bo[codex_panel.buf].bufhidden = 'hide'

    -- Abre o Codex automaticamente dentro desse terminal.
    if codex_panel.job > 0 and vim.fn.executable('codex') == 1 then
      vim.fn.chansend(codex_panel.job, 'codex\n')
    elseif vim.fn.executable('codex') ~= 1 then
      vim.notify('Codex panel: comando `codex` não encontrado no PATH.', vim.log.levels.WARN)
    end
  end

  -- Aparência/comportamento de side panel.
  vim.wo[codex_panel.win].number = false
  vim.wo[codex_panel.win].relativenumber = false
  vim.wo[codex_panel.win].signcolumn = 'no'
  vim.wo[codex_panel.win].winfixwidth = true

  local max_width = math.max(20, vim.o.columns - 20)
  local panel_width = math.min(tonumber(width) or 55, max_width)
  vim.cmd('vertical resize ' .. panel_width)

  vim.cmd('startinsert')
end

-- Comando de apoio, útil também para testar sem depender do atalho.
vim.api.nvim_create_user_command('CodexPanel', function(opts)
  _G.CodexToggle(opts.args ~= '' and tonumber(opts.args) or 55)
end, {
  nargs = '?',
  force = true,
  desc = 'Toggle Codex side panel',
})

------------------------------------------------------------
-- Ctrl+Shift+F --------------------------------------------
------------------------------------------------------------
-- O init.lua já usa Ctrl+F para o NvimTree. Antes de registrar
-- Ctrl+Shift+F, verificamos se o terminal/Neovim o enxerga como
-- uma tecla distinta; se houver colisão, preservamos Ctrl+F.
local lhs = '<C-S-f>'
local modes = { 'n', 'i', 't' }
local has_conflict = false

for _, mode in ipairs(modes) do
  if vim.fn.maparg(lhs, mode) ~= '' then
    has_conflict = true
    break
  end
end

if not has_conflict then
  vim.keymap.set('n', lhs, '<cmd>lua CodexToggle(55)<CR>', {
    silent = true,
    desc = 'Toggle Codex side panel',
  })
  vim.keymap.set('i', lhs, '<Esc><cmd>lua CodexToggle(55)<CR>', {
    silent = true,
    desc = 'Toggle Codex side panel',
  })
  vim.keymap.set('t', lhs, [[<C-\><C-n><cmd>lua CodexToggle(55)<CR>]], {
    silent = true,
    desc = 'Toggle Codex side panel',
  })
else
  vim.schedule(function()
    vim.notify(
      'Codex panel: Ctrl+Shift+F conflita com um mapeamento existente; Ctrl+F foi preservado. Use :CodexPanel.',
      vim.log.levels.WARN
    )
  end)
end
