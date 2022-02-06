local M = {}

local servers = {
  require"config.lsp.null-ls",
  require"config.lsp.nix",
  require"config.lsp.rust",
  require"config.lsp.python",
  require"config.lsp.texlab",
}

local function on_attach(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
  require"aerial".on_attach(client)
  require"lsp_signature".on_attach{
    bind = true,
    handler_opts = {
      border = 'single',
    },
    hint_enable = false,
  }

  if client.resolved_capabilities.document_formatting then
    require"which-key".register({
      ['<leader>rf'] = { function() vim.lsp.buf.formatting() end, 'Format buffer' }
    }, { buffer = bufnr, mode = 'n' })
  elseif client.resolved_capabilities.document_range_formatting then
    require"which-key".register({
      ['<leader>rf'] = { function() vim.lsp.buf.range_formatting() end, 'Format buffer' }
    }, { buffer = bufnr, mode = 'v' })
  end

  require"which-key".register({
    ['<leader>'] = {
      r = { name = 'LSP' }
    },
    ['<leader>r'] = {
      h = { function() require"lspsaga.hover".render_hover_doc() end, 'Show hover info' },
      s = { function() require"lspsaga.signaturehelp".signature_help() end, 'Show signature help' },
      r = { function() require"lspsaga.rename".rename() end, 'Rename identifier' },
      x = { function() require"telescope.builtin".lsp_code_actions() end, 'Code actions' },
    },
    ['g'] = {
      D = { function() vim.lsp.buf.declaration() end, 'Go to declaration' },
      d = { function() require"telescope.builtin".lsp_definitions() end, 'Go to definition' },
      r = { function() require"telescope.builtin".lsp_references() end, 'References' },
      i = { function() require"lspsaga.implement".lspsaga_implementation() end, 'Go to implementation' },
      p = { function() require"lspsaga.diagnostic".navigate("prev")() end, 'Go to previous diagnostic' },
      n = { function() require"lspsaga.diagnostic".navigate("next")() end, 'Go to next diagnostic' },
    },
  }, { buffer = bufnr, mode = 'n' })

  if client.resolved_capabilities.document_symbol then
    require"which-key".register({
          ['<C-s>'] = { function()
            require"nvim-tree".close()
            vim.cmd('AerialClose')
            vim.cmd('AerialOpen')
          end, 'Symbol sidebar' }
    }, { buffer = bufnr, mode = 'n' })
  end

  if client.resolved_capabilities.document_highlight then
    dark_yellow = require"config.colors".colors.dark_yellow
    black = require"config.colors".colors.black
    vim.api.nvim_exec(string.format([[
      hi LspReferenceRead cterm=bold ctermbg=red guifg=%s guibg=%s
      hi LspReferenceText cterm=bold ctermbg=red guifg=%s guibg=%s
      hi LspReferenceWrite cterm=bold ctermbg=red guifg=%s guibg=%s
      augroup lsp_document_highlight
      autocmd! * <buffer>
      autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
      autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]], dark_yellow, black, dark_yellow, black, dark_yellow, black), false)
  end

  if client.resolved_capabilities.code_lens then
    vim.api.nvim_exec([[
      autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
    ]], false)
  end
end

function M.setup()
  require"aerial".setup{
    default_direction = "left",
    max_width = 30,
    min_width = 30,
    placement_editor_edge = true,
  }

  require"lspsaga".setup{
    code_action_icon = "",
    code_action_prompt = {
        virtual_text = false,
    },
    error_sign = "",
    hint_sign = "",
    infor_sign = "",
    warn_sign = "",
  }

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require"cmp_nvim_lsp".update_capabilities(capabilities)
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = {
      prefix = "𥉉 ",
    },
    update_in_insert = true,
  })

  for _, server in pairs(servers) do
    if server ~= nil then
      server.setup(capabilities, on_attach)
    end
  end

  vim.api.nvim_exec([[
    hi! LspCodeLens gui=italic guifg=green
  ]], false)
end

return M
