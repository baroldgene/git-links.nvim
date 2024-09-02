local M = {}

local default_keys = {
  { "<leader>gl", mode = { "n", "v" }, "<cmd>GenerateGitLink<cr>" },
}

M.config = {
  opts = {
    register = "+",
    default_keymaps_enabled = true,
  }
}

local web_repos = function()
  local utils = require("gitlinks.utils")
  return {
    ["github"] = utils.generate_github_url,
    ["bitbucket"] = utils.generate_bitbucket_url
  }
end

M.generate_url = function()
  local utils = require("gitlinks.utils")

  local git_info = utils.get_git_info()
  if (web_repos[git_info.type]) then
    local link = web_repos[git_info.type](git_info)
    vim.fn.setreg(M.config.register, link)
  else
    error('Invalid Repo Type')
  end
end

-- M.init = function()
--   vim.api.nvim_create_user_command("GenerateGitLink", generate_url,
--     { desc = "Generate a git link to view the current code line" })
-- end
vim.api.nvim_create_user_command("GenerateGitLink", M.generate_url,
  { desc = "Generate a git link to view the current code line" })

M.init = function(config)
  if (config.opts.default_keymaps_enabled) then
    M.config.keys = default_keys
  end

  vim.keymap.set({ "v", "n" }, "<Plug>(GenerateGitLink)", function() generate_url() end, { noremap = true })
  vim.api.nvim_create_user_command("GenerateGitLink", M.generate_url,
    { desc = "Generate a git link to view the current code line" })
end


return M
