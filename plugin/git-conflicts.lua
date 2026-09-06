------------------------------------------------------------
-- Git: primeiro marcador de conflito do buffer ------------
------------------------------------------------------------
-- Carregado automaticamente depois do init.lua. Não depende
-- do Gitsigns nem de o arquivo estar sendo rastreado pelo Git.
-- <leader>gc sempre procura desde o início do buffer atual,
-- incluindo alterações ainda não salvas.

vim.keymap.set("n", "<leader>gc", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for lnum, line in ipairs(lines) do
    if line:match("^<<<<<<<") then
      vim.cmd("normal! m'") -- Guarda a posição anterior.
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      vim.cmd("normal! zvzz") -- Abre o fold e centraliza o conflito.
      return
    end
  end

  vim.notify(
    "Nenhum marcador de conflito neste buffer.",
    vim.log.levels.INFO
  )
end, { silent = true, desc = "Git: primeiro conflito" })
