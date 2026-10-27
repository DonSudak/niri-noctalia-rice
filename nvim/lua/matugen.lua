 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1e1e2e',
    base01 = '#313244',
    base02 = '#3a3b50',
    base03 = '#646883',
    base04 = '#a3b4eb',
    base05 = '#cdd6f4',
    base06 = '#cdd6f4',
    base07 = '#cdd6f4',
    base08 = '#f38ba8',
    base09 = '#c6a0f6',
    base0A = '#f5bde6',
    base0B = '#b4befe',
    base0C = '#b98bf4',
    base0D = '#8192fd',
    base0E = '#ee90d5',
    base0F = '#f5bde6',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#cdd6f4',          bg = '#1e1e2e' })
  hi('TelescopeBorder',         { fg = '#646883',             bg = '#1e1e2e' })
  hi('TelescopePromptNormal',   { fg = '#cdd6f4',          bg = '#1e1e2e' })
  hi('TelescopePromptBorder',   { fg = '#646883',             bg = '#1e1e2e' })
  hi('TelescopePromptPrefix',   { fg = '#b4befe',             bg = '#1e1e2e' })
  hi('TelescopePromptCounter',  { fg = '#a3b4eb',  bg = '#1e1e2e' })
  hi('TelescopePromptTitle',    { fg = '#1e1e2e',             bg = '#b4befe' })
  hi('TelescopePreviewTitle',   { fg = '#1e1e2e',             bg = '#f5bde6' })
  hi('TelescopeResultsTitle',   { fg = '#1e1e2e',             bg = '#c6a0f6' })
  hi('TelescopeSelection',      { fg = '#cdd6f4',          bg = '#3a3b50' })
  hi('TelescopeSelectionCaret', { fg = '#b4befe',             bg = '#3a3b50' })
  hi('TelescopeMatching',       { fg = '#b4befe',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#cdd6f4',          bg = '#1e1e2e' })
  hi('MiniPickBorder',         { fg = '#646883',             bg = '#1e1e2e' })
  hi('MiniPickPrompt',   { fg = '#cdd6f4',          bg = '#1e1e2e' })
  hi('MiniPickPromptPrefix',   { fg = '#b4befe',             bg = '#1e1e2e' })
  hi('MiniPickBorderText',    { fg = '#1e1e2e',             bg = '#b4befe' })
  hi('MiniPickMatchCurrent',      { fg = '#cdd6f4',          bg = '#3a3b50' })
  hi('MiniPickPromptCaret', { fg = '#b4befe',             bg = '#3a3b50' })
  hi('MiniPickMatchRanges',       { fg = '#b4befe',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
