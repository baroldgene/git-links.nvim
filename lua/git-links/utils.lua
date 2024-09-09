Utils = {}
local msg_prefix = 'Git-Links: '

function Utils.notify(msg)
  vim.notify(msg_prefix .. msg, vim.log.levels.INFO, { title = 'Git-Links' })
end

function Utils.warn(msg)
  vim.notify(msg_prefix .. msg, vim.log.levels.WARN, { title = 'Git-Links' })
end

function Utils.debug(msg)
  vim.notify(msg_prefix .. msg, vim.log.levels.DEBUG, { title = 'Git-Links' })
end

function Utils.error(msg)
  vim.notify(msg_prefix .. msg, vim.log.levels.ERROR, { title = 'Git-Links' })
end

function Utils.P(val)
  print(vim.inspect(val))
end

local P = Utils.P
local function clean_url(url)
  url = string.gsub(url, "https?://", "")
  url = string.gsub(url, "^origin%s+", "")
  url = string.gsub(url, "%(fetch%)", '')
  url = string.gsub(url, ".*@", '')
  url = string.gsub(url, ':', '/')
  url = string.gsub(url, '%.git', '')
  url = string.gsub(url, "%s+", "")
  return url
end

local function check_sha_remote()
  local branch_result = vim.system({ "git", "branch", "-r", "--contains", Utils.data.hash },
    { cwd = vim.fn.expand("%:p:h") }):wait()

  if branch_result.stdout == "" then
    local success, result = pcall(function()
      return vim.system({ "git", "fetch", "origin", Utils.data.hash }, { cwd = vim.fn.expand("%:p:h") }):wait()
    end)

    if not success or result.code ~= 0 then
      error("Current commit does not exist on remote.", 0)
    end
  end
end

local function check_commit()
  local filename = vim.fn.expand('%:p')
  local fileshort = vim.fn.expand('%:t')
  local result = vim.fn.system("git status --porcelain " .. filename)
  if result ~= "" then
    Utils.warn("Warning: " .. fileshort .. " has uncommitted changes, url may not work as expected.")
  end
end

local function set_repo_type()
  repo = Utils.data.url
  if (string.match(repo, "bitbucket")) then
    Utils.data.type = "bitbucket"
  elseif (string.match(repo, "github")) then
    Utils.data.type = "github"
  else
    error("Failed to detect repo type", 0)
  end
end

local function fetch_url()
  local url
  local remotes = vim.system({ "git", "remote", "-v" }, { cwd = vim.fn.expand("%:p:h") }):wait().stdout
  for s in remotes:gmatch("[^\r\n]+") do
    if (string.gmatch(s, "[github|bitbucket]")) then
      url = s
      break
    end
  end
  if (url) then
    Utils.data.url = clean_url(url)
  else
    error("Remote URL not found.  Is this a git repo?", 0)
  end
end

local function fetch_file_info()
  local filename = vim.fn.expand('%:t')
  local file_path = vim.system({ "git", "ls-files", "--full-name", filename }, { cwd = vim.fn.expand("%:p:h") }):wait()
      .stdout

  file_path = string.gsub(file_path, "%s", "")

  Utils.data.file_path = file_path
end

local function fetch_hash()
  local hash = vim.system({ "git", "rev-parse", "HEAD" }, { cwd = vim.fn.expand("%:p:h") }):wait().stdout
  hash = string.gsub(hash, "%s+", "")
  Utils.data.hash = hash
end

local function get_line_number()
  local starts = vim.fn.line("v")
  local ends = vim.fn.line(".")
  -- data.linenumber = vim.api.nvim_win_get_cursor()[1]
  -- linenumber = vim.api.nvim_win_get_cursor()[1]
  Utils.data.linenumber = { starts = starts, ends = ends }
end

Utils.data = {}

Utils.Steps = {
  { func = fetch_hash,       name = "Fetch Hash" },
  { func = check_commit,     name = "Verify Commits" },
  { func = check_sha_remote, name = "Find Remote Sha" },
  { func = fetch_url,        name = "Fetch Remote URL" },
  { func = set_repo_type,    name = "Detect Repo Type" },
  { func = fetch_file_info,  name = "Fetch File Info" },
  { func = get_line_number,  name = "Find Line Number" },
}

local function run_steps()
  for _, f in ipairs(Utils.Steps) do
    local val, err = pcall(f.func)
    if (not val) then
      Utils.data.errors = { step = f.name, message = err }
      Utils.error("Error attempting to " .. f.name .. ": " .. err)
      return
    end
  end
end
Utils.Get_Git_Info = function()
  Utils.data = {}

  run_steps()

  return Utils.data
end


Utils.generate_bitbucket_url = function(git_info)
  local url = {
    'https://' .. git_info.url,
    '/src/' .. git_info.hash,
    '/' .. git_info.file_path,
    "#lines-" .. git_info.linenumber.starts
  }
  if (git_info.linenumber.starts ~= git_info.linenumber.ends) then
    url[#url + 1] = ":"
    url[#url + 1] = git_info.linenumber.ends
  end
  return table.concat(url, "")
end

Utils.generate_github_url = function(git_info)
  local url = {
    'https://' .. git_info.url,
    '/blob/' .. git_info.hash,
    '/' .. git_info.file_path,
    "#L" .. git_info.linenumber.starts
  }
  if (git_info.linenumber.starts ~= git_info.linenumber.ends) then
    url[#url + 1] = "-L"
    url[#url + 1] = git_info.linenumber.ends
  end
  return table.concat(url, "")
end

return Utils
