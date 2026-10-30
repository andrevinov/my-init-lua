------------------------------------------------------------
-- Fugitive: Git, histórico e resolução de conflitos --------
------------------------------------------------------------
-- O init.lua já instala tpope/vim-fugitive. Este arquivo é
-- carregado automaticamente pelo Neovim depois do init.lua.
-- Preserva os atalhos <leader>g* do Gitsigns e <leader>gc
-- (primeiro conflito), definido em plugin/git-conflicts.lua.

local function fugitive_map(suffix, command, description)
  vim.keymap.set("n", "<leader>g" .. suffix, "<cmd>" .. command .. "<CR>", {
    silent = true,
    desc = "Fugitive: " .. description,
  })
end

-- Operações gerais: não fazem push, commit ou descarte automático.
fugitive_map("g", "Git", "status do repositório")
fugitive_map("f", "Gvdiffsplit", "diff vertical com o index")
fugitive_map("l", "Git blame", "blame do arquivo")
fugitive_map("h", "0Gclog", "histórico do arquivo (quickfix)")
fugitive_map("w", "Gwrite", "salvar e colocar o arquivo no stage")
fugitive_map("m", "Git mergetool", "listar conflitos do merge")

-- Em um arquivo com conflito, Gvdiffsplit! abre o diff de três vias.
-- //2 e //3 são os estágios do index (ours/theirs); em um rebase,
-- "ours" pode não ser o lado da sua branch original.
fugitive_map("xd", "Gvdiffsplit!", "diff de três vias durante merge")
fugitive_map("xo", "diffget //2", "obter trecho do estágio 2 (ours)")
fugitive_map("xt", "diffget //3", "obter trecho do estágio 3 (theirs)")

-- Navega pelos marcadores de abertura (<<<<<<<) do buffer atual,
-- inclusive em alterações ainda não salvas. A busca dá a volta.
local function jump_to_conflict(direction)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local count = #lines
  local current = vim.api.nvim_win_get_cursor(0)[1]

  for step = 1, count do
    local row = ((current - 1 + direction * step) % count) + 1
    if lines[row]:match("^<<<<<<<") then
      vim.cmd("normal! m'") -- Permite voltar à posição anterior com ''.
      vim.api.nvim_win_set_cursor(0, { row, 0 })
      vim.cmd("normal! zvzz") -- Expande folds e centraliza o conflito.
      return
    end
  end

  vim.notify("Nenhum marcador de conflito neste buffer.", vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>gxn", function()
  jump_to_conflict(1)
end, { silent = true, desc = "Git: próximo conflito (circular)" })

vim.keymap.set("n", "<leader>gxp", function()
  jump_to_conflict(-1)
end, { silent = true, desc = "Git: conflito anterior (circular)" })
