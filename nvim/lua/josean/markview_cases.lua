local M = {}

local patched = false
local environment_query = nil
local cached_symbols = nil
local UTF8_CHARPATTERN = "[%z\1-\127\194-\244][\128-\191]*"

local SUPPORTED_ENVIRONMENTS = {
  cases = { left = "brace" },
  dcases = { left = "brace" },
  array = { takes_preamble = true },
  matrix = {},
  smallmatrix = {},
  pmatrix = { left = "paren", right = "paren" },
  bmatrix = { left = "bracket", right = "bracket" },
  Bmatrix = { left = "brace", right = "brace" },
  vmatrix = { left = "bar", right = "bar" },
  Vmatrix = { left = "double_bar", right = "double_bar" },
  aligned = {},
  align = {},
  ["align*"] = {},
  split = {},
  gathered = {},
  gather = {},
  ["gather*"] = {},
}

local COMMAND_WORDS = {
  arg = "arg",
  det = "det",
  diag = "diag",
  dim = "dim",
  exp = "exp",
  gcd = "gcd",
  hom = "hom",
  inf = "inf",
  ker = "ker",
  lcm = "lcm",
  lg = "lg",
  lim = "lim",
  liminf = "liminf",
  limsup = "limsup",
  ln = "ln",
  log = "log",
  max = "max",
  min = "min",
  Pr = "Pr",
  proj = "proj",
  rank = "rank",
  re = "Re",
  im = "Im",
  sin = "sin",
  sinh = "sinh",
  cos = "cos",
  cosh = "cosh",
  tan = "tan",
  tanh = "tanh",
  cot = "cot",
  csc = "csc",
  sec = "sec",
  sup = "sup",
  tr = "tr",
}

local SPACING_COMMANDS = {
  [","] = true,
  [";"] = true,
  ["!"] = true,
  quad = true,
  qquad = true,
  enspace = true,
  thinspace = true,
  medspace = true,
  thickspace = true,
  hspace = true,
  vspace = true,
  space = true,
}

local STYLE_COMMANDS = {
  bm = true,
  boldsymbol = true,
  mathbf = true,
  mathit = true,
  mathrm = true,
  mathsf = true,
  mathtt = true,
  operatorname = true,
  ["operatorname*"] = true,
  text = true,
  textbf = true,
  textit = true,
  textrm = true,
  textsf = true,
  texttt = true,
}

local ESCAPED_CHARS = {
  [" "] = " ",
  ["!"] = "",
  ["#"] = "#",
  ["$"] = "$",
  ["%"] = "%",
  ["&"] = "&",
  ["("] = "(",
  [")"] = ")",
  [","] = " ",
  ["."] = "",
  [";"] = " ",
  ["["] = "[",
  ["]"] = "]",
  ["{"] = "{",
  ["}"] = "}",
  ["|"] = "|",
  ["_"] = "_",
}

local FALLBACK_SYMBOLS = {
  approx = "≈",
  cap = "∩",
  cdot = "·",
  cdots = "...",
  cup = "∪",
  ell = "l",
  equiv = "≡",
  exists = "∃",
  forall = "∀",
  geq = "≥",
  geqslant = "≥",
  ["in"] = "∈",
  ldots = "...",
  leq = "≤",
  leqslant = "≤",
  mapsto = "↦",
  mid = "|",
  mp = "∓",
  nabla = "∇",
  neq = "≠",
  notin = "∉",
  partial = "∂",
  pm = "±",
  propto = "∝",
  subset = "⊂",
  subseteq = "⊆",
  supset = "⊃",
  supseteq = "⊇",
  times = "×",
  to = "→",
}

local SCRIPT_FALLBACKS = {
  superscript = {
    ["*"] = "*",
  },
  subscript = {},
}

local DELIMITER_PRESETS = {
  brace = {
    left = {
      single = "{ ",
      top = "⎧ ",
      middle = "⎪ ",
      center = "⎨ ",
      bottom = "⎩ ",
    },
    right = {
      single = " }",
      top = " ⎫",
      middle = " ⎪",
      center = " ⎬",
      bottom = " ⎭",
    },
  },
  bracket = {
    left = {
      single = "[ ",
      top = "⎡ ",
      middle = "⎢ ",
      bottom = "⎣ ",
    },
    right = {
      single = " ]",
      top = " ⎤",
      middle = " ⎥",
      bottom = " ⎦",
    },
  },
  paren = {
    left = {
      single = "( ",
      top = "⎛ ",
      middle = "⎜ ",
      bottom = "⎝ ",
    },
    right = {
      single = " )",
      top = " ⎞",
      middle = " ⎟",
      bottom = " ⎠",
    },
  },
  bar = {
    left = {
      single = "| ",
      top = "| ",
      middle = "| ",
      bottom = "| ",
    },
    right = {
      single = " |",
      top = " |",
      middle = " |",
      bottom = " |",
    },
  },
  double_bar = {
    left = {
      single = "|| ",
      top = "|| ",
      middle = "|| ",
      bottom = "|| ",
    },
    right = {
      single = " ||",
      top = " ||",
      middle = " ||",
      bottom = " ||",
    },
  },
}

local WRAPPER_PATTERNS = {
  left = {
    { pattern = "\\left%s*\\lbrace%s*$", token = "{" },
    { pattern = "\\left%s*\\{%s*$", token = "{" },
    { pattern = "\\left%s*%[%s*$", token = "[" },
    { pattern = "\\left%s*%(%s*$", token = "(" },
    { pattern = "\\left%s*\\|%s*$", token = "||" },
    { pattern = "\\left%s*|%s*$", token = "|" },
    { pattern = "\\left%s*%.%s*$", token = "." },
  },
  right = {
    { pattern = "^%s*\\right%s*\\rbrace", token = "}" },
    { pattern = "^%s*\\right%s*\\}", token = "}" },
    { pattern = "^%s*\\right%s*%]", token = "]" },
    { pattern = "^%s*\\right%s*%)", token = ")" },
    { pattern = "^%s*\\right%s*\\|", token = "||" },
    { pattern = "^%s*\\right%s*|", token = "|" },
    { pattern = "^%s*\\right%s*%.", token = "." },
  },
}

local WRAPPER_DELIMITERS = {
  ["("] = "paren",
  [")"] = "paren",
  ["["] = "bracket",
  ["]"] = "bracket",
  ["{"] = "brace",
  ["}"] = "brace",
  ["|"] = "bar",
  ["||"] = "double_bar",
}

local function get_symbols()
  if cached_symbols == nil then
    cached_symbols = require("markview.symbols")
  end

  return cached_symbols
end

local function get_environment_query()
  if environment_query then
    return environment_query
  end

  local ok, query = pcall(vim.treesitter.query.parse, "latex", [[
    ([
      (generic_environment)
      (math_environment)
    ] @latex.environment)
  ]])

  if not ok then
    return nil
  end

  environment_query = query
  return environment_query
end

local function trim(text)
  local value = (text or ""):gsub("^%s+", "")
  value = value:gsub("%s+$", "")
  return value
end

local function trim_right(text)
  local value = (text or "")
  value = value:gsub("%s+$", "")
  return value
end

local function collapse_spaces(text)
  return trim((text or ""):gsub("%s+", " "))
end

local function compare_items(left, right)
  if left.range.row_start ~= right.range.row_start then
    return left.range.row_start < right.range.row_start
  end

  if left.range.col_start ~= right.range.col_start then
    return left.range.col_start < right.range.col_start
  end

  if left.range.row_end ~= right.range.row_end then
    return left.range.row_end < right.range.row_end
  end

  if left.range.col_end ~= right.range.col_end then
    return left.range.col_end < right.range.col_end
  end

  return left.class < right.class
end

local function range_within(inner, outer)
  if not inner or not outer then
    return false
  end

  if inner.row_start < outer.row_start or inner.row_end > outer.row_end then
    return false
  end

  if inner.row_start == outer.row_start and inner.col_start < outer.col_start then
    return false
  end

  if inner.row_end == outer.row_end and inner.col_end > outer.col_end then
    return false
  end

  return true
end

local function inside_environment(item, environment_ranges)
  if not item or not item.range or item.class == "latex_environment" then
    return false
  end

  for _, range in ipairs(environment_ranges) do
    if range_within(item.range, range) then
      return true
    end
  end

  return false
end

local function skip_spaces(text, index)
  while index <= #text and text:sub(index, index):match("%s") do
    index = index + 1
  end

  return index
end

local function read_balanced(text, index, open_char, close_char)
  if text:sub(index, index) ~= open_char then
    return nil, index, false
  end

  local depth = 0

  for pos = index, #text do
    local ch = text:sub(pos, pos)

    if ch == open_char then
      depth = depth + 1
    elseif ch == close_char then
      depth = depth - 1

      if depth == 0 then
        return text:sub(index + 1, pos - 1), pos + 1, true
      end
    end
  end

  return text:sub(index + 1), #text + 1, true
end

local function read_command_name(text, index)
  local first = text:sub(index, index)

  if first == "" then
    return "", index
  end

  if first:match("[%a@]") then
    local pos = index

    while text:sub(pos, pos):match("[%a@]") do
      pos = pos + 1
    end

    if text:sub(pos, pos) == "*" then
      pos = pos + 1
    end

    return text:sub(index, pos - 1), pos
  end

  return first, index + 1
end

local normalize_tex

local function read_argument(text, index)
  index = skip_spaces(text, index)

  local ch = text:sub(index, index)

  if ch == "{" then
    return read_balanced(text, index, "{", "}")
  end

  if ch == "\\" then
    local name, next_index = read_command_name(text, index + 1)
    return "\\" .. name, next_index, false
  end

  if ch == "" then
    return nil, index, false
  end

  return ch, index + 1, false
end

local function read_optional_argument(text, index)
  index = skip_spaces(text, index)

  if text:sub(index, index) ~= "[" then
    return nil, index
  end

  local content, next_index = read_balanced(text, index, "[", "]")
  return content, next_index
end

local function normalize_command(name)
  local symbols = get_symbols()

  if COMMAND_WORDS[name] then
    return COMMAND_WORDS[name]
  end

  if symbols.entries[name] then
    return symbols.entries[name]
  end

  if FALLBACK_SYMBOLS[name] then
    return FALLBACK_SYMBOLS[name]
  end

  return "\\" .. name
end

local function map_script(raw, style)
  local symbols = get_symbols()
  local mapping = style == "subscript" and symbols.subscripts or symbols.superscripts
  local fallback = SCRIPT_FALLBACKS[style] or {}

  if raw:sub(1, 1) == "\\" then
    local name = raw:sub(2)
    return mapping[name] or fallback[name]
  end

  local normalized = normalize_tex(raw)
  local output = {}

  for char in normalized:gmatch(UTF8_CHARPATTERN) do
    if mapping[char] then
      table.insert(output, mapping[char])
    elseif fallback[char] then
      table.insert(output, fallback[char])
    else
      return nil, normalized
    end
  end

  return table.concat(output), normalized
end

local function render_script(marker, text, index)
  local raw, next_index, grouped = read_argument(text, index)

  if not raw then
    return marker, index
  end

  local style = marker == "_" and "subscript" or "superscript"
  local mapped, normalized = map_script(raw, style)

  if mapped then
    return mapped, next_index
  end

  normalized = normalized or normalize_tex(raw)

  if grouped then
    return marker .. "(" .. normalized .. ")", next_index
  end

  return marker .. normalized, next_index
end

normalize_tex = function(text)
  local output = {}
  local index = 1

  while index <= #text do
    local ch = text:sub(index, index)

    if ch == "\\" then
      local next_char = text:sub(index + 1, index + 1)

      if next_char == "" then
        break
      end

      if next_char == "\\" then
        table.insert(output, " ")
        index = index + 2

        local _, next_index = read_optional_argument(text, index)
        index = next_index
      elseif next_char:match("[%a@]") then
        local name, next_index = read_command_name(text, index + 1)

        if SPACING_COMMANDS[name] then
          table.insert(output, " ")
          index = next_index
        elseif name == "frac" or name == "dfrac" or name == "tfrac" or name == "cfrac" then
          local numerator, after_numerator = read_argument(text, next_index)
          local denominator, after_denominator = read_argument(text, after_numerator)

          table.insert(output, "(" .. normalize_tex(numerator or "") .. ")/(" .. normalize_tex(denominator or "") .. ")")
          index = after_denominator
        elseif name == "sqrt" then
          local _, after_optional = read_optional_argument(text, next_index)
          local body, after_body = read_argument(text, after_optional)

          table.insert(output, "sqrt(" .. normalize_tex(body or "") .. ")")
          index = after_body
        elseif STYLE_COMMANDS[name] then
          local body, after_body = read_argument(text, next_index)

          if body then
            table.insert(output, normalize_tex(body))
            index = after_body
          else
            table.insert(output, normalize_command(name))
            index = next_index
          end
        elseif name == "left" or name == "right" or name == "big" or name == "Big" or name == "bigl" or name == "bigr" then
          index = next_index
        else
          table.insert(output, normalize_command(name))
          index = next_index
        end
      else
        table.insert(output, ESCAPED_CHARS[next_char] or next_char)
        index = index + 2
      end
    elseif ch == "_" or ch == "^" then
      local rendered, next_index = render_script(ch, text, index + 1)
      table.insert(output, rendered)
      index = next_index
    elseif ch == "{" or ch == "}" then
      index = index + 1
    elseif ch == "~" or ch:match("%s") then
      table.insert(output, " ")
      index = index + 1
    else
      table.insert(output, ch)
      index = index + 1
    end
  end

  return collapse_spaces(table.concat(output))
end

local function split_rows(text)
  local rows = {}
  local current = {}
  local brace_depth = 0
  local bracket_depth = 0
  local index = 1

  while index <= #text do
    local ch = text:sub(index, index)
    local next_char = text:sub(index + 1, index + 1)

    if ch == "\\" and next_char == "\\" and brace_depth == 0 and bracket_depth == 0 then
      table.insert(rows, table.concat(current))
      current = {}
      index = index + 2

      local _, next_index = read_optional_argument(text, index)
      index = next_index
    else
      if ch == "{" then
        brace_depth = brace_depth + 1
      elseif ch == "}" and brace_depth > 0 then
        brace_depth = brace_depth - 1
      elseif ch == "[" then
        bracket_depth = bracket_depth + 1
      elseif ch == "]" and bracket_depth > 0 then
        bracket_depth = bracket_depth - 1
      end

      table.insert(current, ch)
      index = index + 1
    end
  end

  table.insert(rows, table.concat(current))
  return rows
end

local function split_cells(row)
  local cells = {}
  local current = {}
  local brace_depth = 0
  local index = 1

  while index <= #row do
    local ch = row:sub(index, index)
    local next_char = row:sub(index + 1, index + 1)

    if ch == "\\" and next_char == "&" then
      table.insert(current, "&")
      index = index + 2
    elseif ch == "&" and brace_depth == 0 then
      table.insert(cells, table.concat(current))
      current = {}
      index = index + 1
    else
      if ch == "{" then
        brace_depth = brace_depth + 1
      elseif ch == "}" and brace_depth > 0 then
        brace_depth = brace_depth - 1
      end

      table.insert(current, ch)
      index = index + 1
    end
  end

  table.insert(cells, table.concat(current))
  return cells
end

local function get_environment_name(node, buffer)
  for child in node:iter_children() do
    if child:type() == "begin" then
      for begin_child in child:iter_children() do
        if begin_child:type() == "curly_group_text" then
          local text = vim.treesitter.get_node_text(begin_child, buffer) or ""
          return text:gsub("^%{", ""):gsub("%}$", "")
        end
      end
    end
  end

  return nil
end

local function extract_environment_body(node, buffer, environment_spec)
  local parts = {}
  local preamble = nil
  local expect_preamble = environment_spec.takes_preamble == true

  for child in node:iter_children() do
    local child_type = child:type()

    if child_type == "begin" or child_type == "end" then
      goto continue
    end

    if expect_preamble and preamble == nil and child_type == "curly_group" then
      preamble = (vim.treesitter.get_node_text(child, buffer) or ""):gsub("^%{", ""):gsub("%}$", "")
      goto continue
    end

    table.insert(parts, vim.treesitter.get_node_text(child, buffer) or "")

    ::continue::
  end

  return table.concat(parts), preamble
end

local function get_environment_context(node)
  local current = node

  while current do
    if current:type() == "displayed_equation" then
      return "block"
    end

    if current:type() == "inline_formula" then
      return "inline"
    end

    current = current:parent()
  end

  return "block"
end

local function detect_wrapper(line, patterns, offset)
  for _, entry in ipairs(patterns) do
    local start_index, end_index = line:find(entry.pattern)

    if start_index then
      return {
        token = entry.token,
        col_start = offset + start_index - 1,
        col_end = offset + end_index,
      }
    end
  end

  return nil
end

local function detect_wrappers(buffer, range)
  local start_line = vim.api.nvim_buf_get_lines(buffer, range.row_start, range.row_start + 1, false)[1] or ""
  local end_line = vim.api.nvim_buf_get_lines(buffer, range.row_end, range.row_end + 1, false)[1] or ""

  local before = start_line:sub(1, range.col_start)
  local after = end_line:sub(range.col_end + 1)

  return {
    left = detect_wrapper(before, WRAPPER_PATTERNS.left, 0),
    right = detect_wrapper(after, WRAPPER_PATTERNS.right, range.col_end),
  }
end

local function parse_environment_rows(body)
  local rows = {}

  for _, raw_row in ipairs(split_rows(body or "")) do
    local cells = {}

    for _, raw_cell in ipairs(split_cells(raw_row)) do
      table.insert(cells, normalize_tex(raw_cell))
    end

    local has_content = false

    for _, cell in ipairs(cells) do
      if trim(cell) ~= "" then
        has_content = true
        break
      end
    end

    if has_content then
      table.insert(rows, {
        cells = cells,
        raw = raw_row,
      })
    end
  end

  return rows
end

local function wrapper_range(wrapper, row)
  if not wrapper then
    return nil
  end

  return {
    row_start = row,
    col_start = wrapper.col_start,
    row_end = row,
    col_end = wrapper.col_end,
  }
end

local function get_environment_item(node, buffer)
  local name = get_environment_name(node, buffer)
  local environment_spec = name and SUPPORTED_ENVIRONMENTS[name] or nil

  if not environment_spec then
    return nil
  end

  local row_start, col_start, row_end, col_end = node:range()
  local body, preamble = extract_environment_body(node, buffer, environment_spec)
  local rows = parse_environment_rows(body)

  if vim.tbl_isempty(rows) then
    return nil
  end

  local wrappers = detect_wrappers(buffer, {
    row_start = row_start,
    col_start = col_start,
    row_end = row_end,
    col_end = col_end,
  })

  local filter_ranges = {
    {
      row_start = row_start,
      col_start = col_start,
      row_end = row_end,
      col_end = col_end,
    },
  }

  if wrappers.left then
    table.insert(filter_ranges, wrapper_range(wrappers.left, row_start))
  end

  if wrappers.right then
    table.insert(filter_ranges, wrapper_range(wrappers.right, row_end))
  end

  return {
    class = "latex_environment",
    environment = name,
    spec = environment_spec,
    preamble = preamble,
    rows = rows,
    context = get_environment_context(node),
    wrappers = wrappers,
    filter_ranges = filter_ranges,
    range = {
      row_start = row_start,
      col_start = col_start,
      row_end = row_end,
      col_end = col_end,
    },
  }
end

local function column_widths(rows)
  local widths = {}
  local max_columns = 0

  for _, row in ipairs(rows) do
    max_columns = math.max(max_columns, #row.cells)
  end

  for column = 1, max_columns do
    widths[column] = 0
  end

  for _, row in ipairs(rows) do
    for column = 1, max_columns do
      local cell = row.cells[column] or ""
      widths[column] = math.max(widths[column], vim.fn.strdisplaywidth(cell))
    end
  end

  if max_columns == 0 then
    return { 0 }
  end

  return widths
end

local function row_text(row, widths)
  local pieces = {}

  for column = 1, #widths do
    local cell = row.cells[column] or ""
    local padding = math.max(0, widths[column] - vim.fn.strdisplaywidth(cell))

    table.insert(pieces, cell)

    if column < #widths then
      table.insert(pieces, string.rep(" ", padding + 2))
    end
  end

  return trim_right(table.concat(pieces))
end

local function resolve_delimiters(item)
  local left = item.spec.left
  local right = item.spec.right

  if not left and item.wrappers.left then
    left = WRAPPER_DELIMITERS[item.wrappers.left.token]
  end

  if not right and item.wrappers.right then
    right = WRAPPER_DELIMITERS[item.wrappers.right.token]
  end

  return {
    left = left,
    right = right,
  }
end

local function delimiter_segment(kind, side, index, total)
  local preset = kind and DELIMITER_PRESETS[kind] or nil
  local values = preset and preset[side] or nil

  if not values then
    return nil
  end

  if total <= 1 then
    return values.single or values.top or values.middle or values.bottom
  end

  if index == 1 then
    return values.top or values.middle or values.single
  end

  if index == total then
    return values.bottom or values.middle or values.single
  end

  if values.center and total % 2 == 1 and index == math.ceil(total / 2) then
    return values.center
  end

  return values.middle or values.center or values.single
end

local function build_display_lines(item, content_hl, delimiter_hl)
  local lines = {}
  local widths = column_widths(item.rows)
  local delimiters = resolve_delimiters(item)

  for index, row in ipairs(item.rows) do
    local segments = {}
    local left = delimiter_segment(delimiters.left, "left", index, #item.rows)
    local right = delimiter_segment(delimiters.right, "right", index, #item.rows)

    if left and left ~= "" then
      table.insert(segments, { left, delimiter_hl })
    end

    table.insert(segments, { row_text(row, widths), content_hl })

    if right and right ~= "" then
      table.insert(segments, { right, delimiter_hl })
    end

    table.insert(lines, segments)
  end

  return lines
end

local function build_compact_line(item, content_hl, delimiter_hl)
  local widths = column_widths(item.rows)
  local delimiters = resolve_delimiters(item)
  local row_texts = {}

  for _, row in ipairs(item.rows) do
    table.insert(row_texts, row_text(row, widths))
  end

  local segments = {}
  local left = delimiter_segment(delimiters.left, "left", 1, 1)
  local right = delimiter_segment(delimiters.right, "right", 1, 1)

  if left and left ~= "" then
    table.insert(segments, { left, delimiter_hl })
  end

  table.insert(segments, { table.concat(row_texts, "; "), content_hl })

  if right and right ~= "" then
    table.insert(segments, { right, delimiter_hl })
  end

  return segments
end

local function render_start_col(item)
  if item.wrappers.left then
    return item.wrappers.left.col_start
  end

  return item.range.col_start
end

local function render_end_col(buffer, item)
  if item.range.row_start == item.range.row_end then
    if item.wrappers.right then
      return item.wrappers.right.col_end
    end

    return item.range.col_end
  end

  local start_line = vim.api.nvim_buf_get_lines(buffer, item.range.row_start, item.range.row_start + 1, false)[1] or ""
  return #start_line
end

function M.patch()
  if patched then
    return
  end

  local parser = require("markview.parsers.latex")
  local renderer = require("markview.renderers.latex")
  local root_renderer = require("markview.renderer")
  local spec = require("markview.spec")
  local utils = require("markview.utils")

  local original_parse = parser.parse

  parser.parse = function(buffer, tree, from, to)
    local content, sorted = original_parse(buffer, tree, from, to)
    local query = get_environment_query()
    local environment_ranges = {}

    content = content or {}
    sorted = sorted or {}
    sorted.latex_environment = sorted.latex_environment or {}

    if query then
      for _, node in query:iter_captures(tree:root(), buffer, from, to) do
        local item = get_environment_item(node, buffer)

        if item then
          table.insert(content, item)
          table.insert(sorted.latex_environment, item)

          for _, range in ipairs(item.filter_ranges or { item.range }) do
            table.insert(environment_ranges, range)
          end
        end
      end
    end

    if #environment_ranges > 0 then
      content = vim.tbl_filter(function(item)
        return not inside_environment(item, environment_ranges)
      end, content)

      for class_name, items in pairs(sorted) do
        if class_name ~= "latex_environment" then
          sorted[class_name] = vim.tbl_filter(function(item)
            return not inside_environment(item, environment_ranges)
          end, items)
        end
      end
    end

    table.sort(content, compare_items)
    return content, sorted
  end

  renderer.environment = function(buffer, item)
    if not item.rows or vim.tbl_isempty(item.rows) then
      return
    end

    local block_config = spec.get({ "latex", "blocks" }, {
      fallback = {},
      eval_args = { buffer, item },
    }) or {}

    local content_hl = utils.set_hl(block_config.hl) or "Normal"
    local delimiter_hl = utils.set_hl(block_config.text_hl or block_config.hl) or content_hl
    local start_col = render_start_col(item)
    local end_col = math.max(start_col + 1, render_end_col(buffer, item))

    if item.context == "inline" then
      utils.set_extmark(buffer, renderer.ns, item.range.row_start, start_col, {
        end_col = end_col,
        conceal = "",
        virt_text_pos = "overlay",
        virt_text = build_compact_line(item, content_hl, delimiter_hl),
      })

      return
    end

    local display_lines = build_display_lines(item, content_hl, delimiter_hl)
    local first_line = table.remove(display_lines, 1)

    if not first_line then
      return
    end

    utils.set_extmark(buffer, renderer.ns, item.range.row_start, start_col, {
      end_col = end_col,
      conceal = "",
      virt_text_pos = "overlay",
      virt_text = first_line,
      virt_lines = #display_lines > 0 and display_lines or nil,
    })

    if item.range.row_end > item.range.row_start then
      utils.set_extmark(buffer, renderer.ns, item.range.row_start + 1, 0, {
        end_row = item.range.row_end + 1,
        conceal_lines = "",
      })
    end
  end

  root_renderer.option_maps.latex.environments = { "latex_environment" }
  patched = true
end

return M
