# github-links.nvim
Have you ever been spelunking through code and then needed to show someone the line you're looking at?  This plugin allows you to quickly generate a link to the specific line(s) of code you are on in the github or bitbucket web UI and put it in the `+` register (register can be customized).

# Installation

Designed for LazyVim (since that's what I use).  You can install by adding the following file:
`plugins/git-links.lua` 
With the contents:

```
return {
  dir = '~/code/Personal/nvim/git-links.nvim/',
  opts = {}
}
```


# Default Values
This plugin has the following defaults that can be overridden using `opts=` in the initialization.  Here is the full spec:
```
return {
  dir = '~/code/Personal/nvim/git-links.nvim/',
  opts = {
    hotkey = "<leader>gw",
    register = "+",
  }
}
```

# Bugs and Feature Requests
Please report bugs or feature requests via github issues.  Please keep in mind this is my first ever nvim plugin.
