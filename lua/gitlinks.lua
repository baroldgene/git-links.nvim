local M = {}

local utils = require("gitlinks.utils")

default_config = {
  register = "+",
  hotkey = "<leader>gl",
  enable_hotkey = true,
}

GitlinksConfig = GitlinksConfig or default_config

M.gitlinks = function(config)

end



local web_repos = {
  ["github"] = utils.generate_github_url,
  ["bitbucket"] = utils.generate_bitbucket_url
}

local generate_url = function()
  local git_info = utils.get_git_info()
  if (web_repos[git_info.type]) then
    local link = web_repos[git_info.type](git_info)
    vim.fn.setreg("+", link)
  else
    error('Invalid Repo Type')
  end
end

vim.api.nvim_create_user_command("GenerateGitLink", generate_url,
  { desc = "Generate a git link to view the current code line" })


M.setup = function(config)
  if not config then
    local config = default_config
  end

  GitlinksConfig = config


  vim.api.nvim_create_user_command("GenerateGitLink", generate_url,
    { desc = "Generate a git link to view the current code line" })

  vim.keymap.set("n", "<Plug>(GenerateGitLink)", generate_url, { noremap = true })
end


return M
