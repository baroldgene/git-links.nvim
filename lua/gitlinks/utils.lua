Utils = {}


local function clean_url(url)
  url = string.gsub(url, "https?:\\/\\//", '')
  url = string.gsub(url, "%(fetch%)", '')
  url = string.gsub(url, ".*@", '')
  url = string.gsub(url, ':', '/')
  url = string.gsub(url, '%.git', '')
  url = string.gsub(url, "%s+", "")
  return url
end

local function repo_type(repo)
  if (string.match(repo, "bitbucket")) then
    return "bitbucket"
  elseif (string.match(repo, "github")) then
    return "github"
  end
end

local function fetch_url()
  local remotes = vim.fn.system("git remote -v")
  for s in remotes:gmatch("[^\r\n]+") do
    if (string.match(s, "github")) then
      return s
    elseif (string.match(s, "bitbucket")) then
      return s
    end
  end
end

local function fetch_file_info()
  local filename = vim.fn.expand('%:t')
  local cmd = "git ls-files --full-name | grep " .. filename
  local file_path = vim.fn.system(cmd)

  file_path = string.gsub(file_path, "%s", "")

  return file_path
end


Utils.get_git_info = function()
  local data = {}

  local url = fetch_url()
  url = clean_url(url)
  data.url = url

  local hash = vim.fn.system("git rev-parse --short HEAD")
  hash = string.gsub(hash, "%s+", "")
  data.hash = hash

  -- local hash = vim.fn.system("git status | awk '/On branch/ {print $3}'")
  -- hash = string.gsub(hash, "%s+", "")
  -- print(hash)
  -- data.hash = hash

  data.type = repo_type(url)

  data.file_path = fetch_file_info()

  data.linenumber = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())[1]

  return data
end


Utils.generate_bitbucket_url = function(git_info)
  local url = {
    'https://' .. git_info.url,
    '/src/' .. git_info.hash,
    '/' .. git_info.file_path,
    "#lines-" .. git_info.linenumber
  }
  return table.concat(url, "")
end

Utils.generate_github_url = function(git_info)
  local url = {
    'https://' .. git_info.url,
    '/blob/' .. git_info.hash,
    '/' .. git_info.file_path,
    "#L" .. git_info.linenumber
  }
  return table.concat(url, "")
end

return Utils
