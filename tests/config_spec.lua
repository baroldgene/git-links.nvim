local assert = require("luassert")
local stub = require('luassert.stub')
local match = require('luassert.match')
-- local mock = require('luassert.mock')
local P = function(var)
  print(vim.inspect(var))
end

local base_function = function(cmd)
  if cmd[1] == "git" and cmd[2] == "remote" then
    return { wait = function() return { code = 0, stdout = "origin\thttps://github.com/user/repo.git (fetch)" } end }
  elseif cmd[1] == "git" and cmd[2] == "ls-files" then
    return { wait = function() return { code = 0, stdout = "path/to/file.lua" } end }
  elseif cmd[1] == "git" and cmd[2] == "rev-parse" then
    return { wait = function() return { code = 0, stdout = "abcdef1" } end }
  end
end

describe("git-links", function()
  local original_system_cmd
  local fail_functions = {
    none_github = function(cmd)
      if cmd[1] == "git" and cmd[2] == "remote" then
        return { wait = function() return { code = 0, stdout = "origin\thttps://github.com/user/repo.git (fetch)" } end }
      else
        return base_function(cmd)
      end
    end,
    none_bitbucket = function(cmd)
      if cmd[1] == "git" and cmd[2] == "remote" then
        return { wait = function() return { code = 0, stdout = "origin\thttps://bitbucket.com/user/repo.git (fetch)" } end }
      else
        return base_function(cmd)
      end
    end,
    ls_files = function(cmd)
      if cmd[1] == "git" and cmd[2] == "ls-files" then
        return { wait = function() return { code = 1, stdout = "", stderr = "System Error" } end }
      else
        return base_function(cmd)
      end
    end,
    git_remote = function(cmd)
      if cmd[1] == "git" and cmd[2] == "remote" then
        return { wait = function() return { code = 1, stdout = "", stderr = "fatal: not a git repository" } end }
      else
        return base_function(cmd)
      end
    end,
    rev_parse = function(cmd)
      if cmd[1] == "git" and cmd[2] == "rev-parse" then
        return { wait = function() return { code = 1, stdout = "", stderr = "fatal: not a git repository" } end }
      else
        return base_function(cmd)
      end
    end,
    
    any = function(_)
      return { wait = function() return { code = 1, stdout = "", stderr = "Some Error" } end }
    end,
    no_remotes = function(cmd)
      if cmd[1] == "git" and cmd[2] == "remote" then
        return { wait = function() return { code = 0, stdout = "" } end }
      else
        return base_function(cmd)
      end
    end
  }

  before_each(function()
    original_system_cmd = vim.system
    stub(vim, "notify", function() return 0 end)
    stub(vim.fn, "setreg")
    stub(vim.fn, "expand", function(arg)
      if arg == "%:p:h" then return "/path/to/repo" end
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
    stub(vim.keymap, "set")
    require("git-links").setup({ hotkey = "" })
    assert.stub(vim.keymap.set).was_called(0)
    vim.keymap.set:revert()
  end)

  it("Can use a different register", function()
    local gitlinks = require("git-links")
    gitlinks.setup({ register = "1" })
    vim.system = fail_functions.none_github

    gitlinks.generate_url()
    assert.stub(vim.fn.setreg).was_called_with("1", "https://github.com/user/repo/blob/abcdef1/path/to/file.lua#L10-L15")
  end)

  it("Gets a proper github URL", function()
    local gitlinks = require("git-links")
    gitlinks.setup({})
    vim.system = fail_functions.none_github

    gitlinks.generate_url()
    assert.stub(vim.fn.setreg).was_called_with("+", "https://github.com/user/repo/blob/abcdef1/path/to/file.lua#L10-L15")
  end)

  it("Gets a proper bitbucket URL", function()
    vim.system = fail_functions.none_bitbucket
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.fn.setreg).was_called_with("+",
      "https://bitbucket.com/user/repo/src/abcdef1/path/to/file.lua#lines-10:15")

  end)

  it("Fails gracefully when no acceptable remote is found", function()
    vim.system = fail_functions.no_remotes
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch Remote URL"), vim.log.levels
      .ERROR, match._)
  end)

  it("Handles error when git remote fails", function()
    vim.system = fail_functions.git_remote
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch Remote URL"), vim.log.levels
      .ERROR, match._)
  end)

  it("Handles error when git ls-files fails", function()
    vim.system = fail_functions.ls_files
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch File Info"), vim.log.levels.ERROR,
      match._)
  end)

  it("Handles error when git rev-parse fails", function()
    vim.system = fail_functions.rev_parse
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.notify).was_called(2) --  First call is the "loaded" notification
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch Hash"), vim.log.levels.ERROR,
      match._
    )
  end)

  it("Stops execution on the first error", function()
    local call_count = 0
    vim.system = fail_functions.any
    local gitlinks = require("git-links")
    gitlinks.setup({})

    gitlinks.generate_url()
    assert.stub(vim.notify).was_called(2) -- First call is the "loaded" notification
    assert.stub(vim.notify).was_called_with(match.has_match("Error attempting to Fetch Remote URL"),
      vim.log.levels.ERROR, match._)
  end)

end)
