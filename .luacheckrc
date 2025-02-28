-- Luacheckrc for Claude Code plugin

std = {
  globals = {
    "vim",
    "table",
    "string",
    "math",
    "os",
    "io",
  },
  read_globals = {
    "jit",
    "require",
    "pcall",
    "type",
    "ipairs",
    "pairs",
    "tostring",
    "tonumber",
    "error",
    "assert",
    "_VERSION",
  },
}

-- Patterns for files to exclude
exclude_files = {
  ".luarocks/*",
  "lua/plenary/*",
  "tests/plenary/*",
}

-- Allow unused self arguments of methods
self = false

-- Don't report unused arguments/locals
unused_args = false
unused = false

-- Ignore warnings related to whitespace
ignore = {
  "611", -- Line contains trailing whitespace
  "612", -- Line contains trailing whitespace in a comment
  "613", -- Line contains trailing whitespace in a string
  "614", -- Line contains only whitespace
}

-- Maximum line length
max_line_length = 120