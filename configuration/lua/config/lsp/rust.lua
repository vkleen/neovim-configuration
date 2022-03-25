local M = {}

function M.setup(capabilities, on_attach)
  require"rust-tools".setup{
    server = {
      capabilities = capabilities,
      on_attach = on_attach,
    },
    runnables = {
      use_telescope = true,
    },
    debuggables = {
        use_telescope = true,
    },
    tools = {
      hover_with_actions = false,
    },
  }
end

return M
