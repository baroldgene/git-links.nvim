local M = {}


M.default_opts = {
  hotkey = "<leader>gw",
  register = "+"
}

M.keys = {
  { "<leader>ii", mode = { "n", "v" }, "<cmd>GenerateGitLink<cr>" },
}

M.config = {}

M.generate_url = function()
  local utils = require("git-links.utils")
  local web_repos =
  {
    ["github"] = utils.generate_github_url,
    ["bitbucket"] = utils.generate_bitbucket_url
  }

  local git_info = utils.Get_Git_Info()
  if (not git_info.errors) then
    local link = web_repos[git_info.type](git_info)
    vim.fn.setreg(M.config.register, link)
    utils.notify("Git Link copied to clipboard")
  end
end

M.setup = function(config)
  config = vim.tbl_deep_extend('keep', config, M.default_opts)
  M.config = config

  local utils = require("git-links.utils")
  vim.api.nvim_create_user_command("GenerateGitLink", M.generate_url, { desc = "Generate a git link to current line(s)" })
  if (config.hotkey ~= "") then
    vim.keymap.set({ "n", "v" }, config.hotkey, "<cmd>GenerateGitLink<cr>", { noremap = true })
  end
  utils.notify("Loaded Plugin")
end


return M
