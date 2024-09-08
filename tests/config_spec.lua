local find_map = function(maps, input)
  for _, map in ipairs(maps) do
    if (map.lhs == input or map.rhs == input) then
      return map
    end
  end
end

local assert = require("luassert")
local mock = require('luassert.mock')
local stub = require('luassert.stub')
local match = require('luassert.match')
local spy = require('luassert.spy')
local P = function(var)
  print(vim.inspect(var))
end

local function tbl_contains(state, arguments)
  local expected = arguments[1]
  return function(tbl)
    P(tbl)
    P(expected)
    for index, value in ipairs(tbl) do
      if value == expected then
        return true
      end
    end
  end
end

assert:register("matcher", "tbl_contains", tbl_contains)
describe("git-links", function()
  it("Disables keymap when desired", function()
    local set_keymap = spy.on(vim.keymap, "set")
    require("git-links").setup({ hotkey = "" })
    assert.spy(set_keymap).was_called(0)
  end)

  it("Has a default keymap", function()
    local set_keymap = spy.on(vim.keymap, "set")
    require("git-links").setup({})
    assert.spy(set_keymap).was_called(1)
    assert.spy(set_keymap).was_called_with(match._, "<leader>gw", "<cmd>GenerateGitLink<cr>", match._)
  end)

  -- TODO: Implement This
  it("Gets a proper github URL", function()
    local revert_func = vim.sytem
    vim.system = function(...)
      local args = { ... }
      print("Arg List:")
      P(arg)
      return revert_func(arg)
    end
    link = require("git-links").generate_url()
    print("Link:")
    print(link)
    vim.system = revert_func

  end)

  -- TODO: Implement This
  it("Gets a proper bitbucket URL", function()

  end)

  -- TODO: Implement This
  it("Works when the root isn't the git root", function()

  end)

  -- TODO: Implement This
  it("Errors as expected when not a git repository", function()

  end)

  -- TODO: Implement This
  it("Provides a useful error message", function()

  end)

  -- TODO: Implement This
  it("Stops execution on the first error", function()
  end)
end)
