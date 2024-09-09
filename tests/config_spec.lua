local assert = require("luassert")
local stub = require('luassert.stub')
local match = require('luassert.match')
-- local mock = require('luassert.mock')
local P = function(var)
  print(vim.inspect(var))
end

local github_url = "origin\thttps://github.com/user/repo.git (fetch)"
local bitbucket_url = "origin\thttps://bitbucket.com/user/repo.git (fetch)"

local steps = {
  git_remote = {
    cmd = "remote",
    suc = { code = 0, stdout = "origin\thttps://github.com/user/repo.git (fetch)" },
    fail = { code = 1, stdout = "", stderr = "fatal: not a git repository" }
  },
  ls_files = {
    cmd = "ls-files",
    suc = { code = 0, stdout = "path/to/file.lua" },
    fail = { code = 1, stdout = "", stderr = "System Error" }
  },
  rev_parse = {
    cmd = "rev-parse",
    suc = { code = 0, stdout = "abcdef1" },
    fail = { code = 1, stdout = "", stderr = "fatal: not a git repository" }
  },
  git_status = {
    cmd = "status",
    suc = { code = 0, stdout = '' },
    fail = { code = 0, stdout = 'Non-Blank Text' }
  },
  fetch = {
    cmd = "fetch",
    suc = { code = 0, stdout = "" },
    fail = { code = 0, stdout = "" }
  },
  branch = {
    cmd = "branch",
    suc = {
      code = 0,
      stdout =
      "From github.com:baroldgene/github-links.nvim * branch            ef76f554bd25ea851f93549dd883007c2dba9a0e -> FETCH_HEAD"
    },
    fail = { code = 1, stdout = "" }
  }
}

local wait_func = function(val)
  return { wait = function() return val end }
end

local make_sys_stub = function(custom_steps)
  if host == nil then host = "github" end
  return function(cmd)
    for k, v in pairs(steps) do
      if cmd[2] == v.cmd then
        if (custom_steps[k] ~= nil) then
          return wait_func(custom_steps[k])
        else
          return wait_func(v.suc)
        end
      end
    end
  end
end
describe("git-links", function()
  local original_system_cmd

  before_each(function()
    original_system_cmd = vim.system
    stub(vim, "notify", function(message)
      P(message)
      return 0
    end)
    stub(vim.fn, "setreg")
    stub(vim.fn, "expand", function(arg)
      if arg == "%:p:h" then return "/path/to/repo" end
      if arg == "%:p" then return "/path/to/repo" end
      if arg == "%:t" then return "file.lua" end
    end)

    stub(vim.fn, "line", function(arg)
      if arg == "v" then return 10 end
      if arg == "." then return 15 end
    end)
  end)

  after_each(function()
    vim.system = original_system_cmd
    vim.fn.expand:revert()
    vim.fn.line:revert()
    vim.fn.setreg:revert()
    vim.notify:revert()
  end)

  it("Sets a default keymap", function()
    stub(vim.keymap, "set")
    require("git-links").setup({})
    assert.stub(vim.keymap.set).was_called(1)
    assert.stub(vim.keymap.set).was_called_with(match._, "<leader>gw", "<cmd>GenerateGitLink<cr>", match._)
    vim.keymap.set:revert()
  end)
  it("Disables keymap when desired", function()
    require("git-links").setup({ hotkey = "" })
    local maps = vim.api.nvim_get_keymap("n")
    local found = find_map(maps, "<Cmd>GenerateGitLink<CR>")

    if (found ~= nil) then
      P(found)
    end
  end)

  before_each(function()
    original_system_cmd = vim.system
    stub(vim, "notify", function(msg)
      P(msg)
      return 0
    end)
    stub(vim.fn, "setreg")
    stub(vim.fn, "expand", function(arg)
      if arg == "%:p:h" then return "/path/to/repo" end
      if arg == "%:p" then return "/path/to/repo" end
      if arg == "%:t" then return "file.lua" end
    end)

    stub(vim.fn, "line", function(arg)
      if arg == "v" then return 10 end
      if arg == "." then return 15 end
    end)
  end)

  it("Can use a different register", function()
    local gitlinks = require("git-links")
    gitlinks.setup({ register = "1" })
    vim.system = make_sys_stub({})

    gitlinks.generate_url()
    assert.stub(vim.fn.setreg).was_called_with("1", "https://github.com/user/repo/blob/abcdef1/path/to/file.lua#L10-L15")
  end)

  it("Handles multi-line input", function()
    local gitlinks = require("git-links")
    require("git-links").setup({})
    vim.system = make_sys_stub({})

    assert.is_false(found == nil)
  end)

  it("Handles single-line input", function()
    local gitlinks = require("git-links")
    require("git-links").setup({})
    stub(vim.fn, "line", function(_)
      return 10
    end)
    vim.system = make_sys_stub({})

    gitlinks.generate_url()
    assert.stub(vim.fn.setreg).was_called_with("+", "https://github.com/user/repo/blob/abcdef1/path/to/file.lua#L10")
    vim.fn.line:revert()
  end)
  it("Gets a proper github URL", function()
    local gitlinks = require("git-links")
    gitlinks.setup({})
    vim.system = make_sys_stub({})
    assert.stub(vim.fn.setreg).was_called_with("+", "https://github.com/user/repo/blob/abcdef1/path/to/file.lua#L10")

    gitlinks.generate_url()
    assert.stub(vim.fn.setreg).was_called_with("+", "https://github.com/user/repo/blob/abcdef1/path/to/file.lua#L10-L15")
  end)

  it("Gets a proper bitbucket URL", function()
    vim.system = make_sys_stub({ git_remote = "origin\thttps://bitbucket.com/user/repo.git (fetch)" })
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.fn.setreg).was_called_with("+",
      "https://bitbucket.com/user/repo/src/abcdef1/path/to/file.lua#lines-10:15")
  end)

  it("Fails gracefully when no acceptable remote is found", function()
    vim.system = make_sys_stub({ git_remotes = { code = 0, stdout = "" } })
    local gitlinks = require("git-links")
    gitlinks.setup({})
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch Remote URL"), vim.log.levels
      .ERROR, match._)

  end)

  it("Handles error when git remote fails", function()
    vim.system = make_sys_stub({ "git_remotes" })
    local gitlinks = require("git-links")

    gitlinks.setup({})
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch Remote URL"),
      vim.log.levels.ERROR, match._)
  end)

  it("Handles error when git ls-files fails", function()
    vim.system = make_sys_stub({ "ls_files" })
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch File Info"),
      vim.log.levels.ERROR,
      match._)
  end)

  it("Handles error when git rev-parse fails", function()
    vim.system = make_sys_stub({ "rev_parse" })
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.notify).was_called(2) --  First call is the "loaded" notification
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch Hash"), vim.log.levels.ERROR,
      match._
    )
  end)

  it("Stops execution on the first error", function()
    vim.system = make_sys_stub.any
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.notify).was_called(2) -- First call is the "loaded" notification
    assert.stub(vim.notify).was_called_with(match.has_match("Unable to determine commit hash"),
      vim.log.levels.ERROR, match._)
  end)
  it("Checks git remote if local check fails", function()
    vim.system = make_sys_stub({ "fetch" })
    local gitlinks = require("git-links")
    gitlinks.setup({})

    stub(vim, "system")

    gitlinks.generate_url()
    assert.stub(vim.system).called(1)
  end)

  it("Checks fails without git remote and local check ", function()
    vim.system = make_sys_stub({ "fetch" })
    local gitlinks = require("git-links")
    gitlinks.setup({})

    stub(vim, "system")

    gitlinks.generate_url()
    assert.stub(vim.system).called(1)
  end)
  end)
