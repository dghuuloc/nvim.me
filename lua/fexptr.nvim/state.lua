local uv = vim.loop

return {
  root = uv.cwd(),
  win = nil,
  buf = nil,
  tree = {},
  expanded = vim.g.fexptr_expanded or {},
  clipboard = nil,
  cursor = {1, 0},
}
