local find_map = function(maps, input)
  for _, map in ipairs(maps) do
    if (map.lhs == input or map.rhs == input) then
      return map
    end
  end
end

local P = function(var)
  print(vim.inspect(var))
end

describe("git-links", function()
  it("Disables keymap when desired", function()
    require("git-links").setup({ hotkey = "" })
    local maps = vim.api.nvim_get_keymap("n")
    local found = find_map(maps, "<Cmd>GenerateGitLink<CR>")

    if (found ~= nil) then
      P(found)
    end

    assert.is_true(found == nil)
  end)

  it("Has a default keymap", function()
    require("git-links").setup({})
    vim.g.mapleader = " "
    local maps = vim.api.nvim_get_keymap("n")
    local found = find_map(maps, "<Cmd>GenerateGitLink<CR>")

    assert.is_false(found == nil)
  end)

  -- TODO: Implement This
  it("Gets a proper github URL", function()

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
