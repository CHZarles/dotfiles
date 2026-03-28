local M = {}

local notify_title = "model.nvim"
local default_model = "gpt-5.4"
local default_verbosity = "high"
local default_wire_api = "responses"
local markdown_filetypes = {
  markdown = true,
  quarto = true,
  rmd = true,
  asciidoc = true,
}

local codex_responses_provider = {}

local function is_list(value)
  if vim.islist then
    return vim.islist(value)
  end

  if type(value) ~= "table" then
    return false
  end

  local count = 0
  for key in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
      return false
    end
    count = count + 1
  end

  for index = 1, count do
    if value[index] == nil then
      return false
    end
  end

  return true
end

local function is_blank(value)
  return value == nil or vim.trim(value) == ""
end

local function normalize_url(url)
  if is_blank(url) then
    return nil
  end

  if url:sub(-1) ~= "/" then
    return url .. "/"
  end

  return url
end

local function provider_config()
  local api_key = vim.env.OPENAI_API_KEY
  local base_url = normalize_url(vim.env.OPENAI_BASE_URL)
  local model = is_blank(vim.env.OPENAI_MODEL) and default_model or vim.env.OPENAI_MODEL
  local verbosity = is_blank(vim.env.MODEL_TRANSLATE_VERBOSITY) and default_verbosity or vim.env.MODEL_TRANSLATE_VERBOSITY
  local wire_api = is_blank(vim.env.MODEL_TRANSLATE_WIRE_API) and default_wire_api or vim.env.MODEL_TRANSLATE_WIRE_API

  if is_blank(base_url) then
    return nil, "Missing OPENAI_BASE_URL. Export your OpenAI-compatible base URL before using translation."
  end

  if is_blank(api_key) then
    return nil, "Missing OPENAI_API_KEY. Export your API key before using translation."
  end

  if wire_api == "chat" then
    wire_api = "chat/completions"
  end

  if wire_api ~= "responses" and wire_api ~= "chat/completions" then
    return nil, "Unsupported MODEL_TRANSLATE_WIRE_API. Use 'responses' or 'chat/completions'."
  end

  return {
    api_key = api_key,
    base_url = base_url,
    model = model,
    verbosity = verbosity,
    wire_api = wire_api,
  }
end

local function extract_response_text(node, chunks)
  if type(node) ~= "table" then
    return
  end

  if node.type == "output_text" and type(node.text) == "string" then
    table.insert(chunks, node.text)
  end

  if type(node.output_text) == "string" then
    table.insert(chunks, node.output_text)
  end

  if type(node.text) == "table" and type(node.text.value) == "string" then
    table.insert(chunks, node.text.value)
  end

  for _, key in ipairs({ "output", "content" }) do
    local value = node[key]
    if is_list(value) then
      for _, item in ipairs(value) do
        extract_response_text(item, chunks)
      end
    end
  end
end

function codex_responses_provider.request_completion(handlers, params, options)
  options = options or {}

  local base_url = normalize_url(options.url)
  if is_blank(base_url) then
    handlers.on_error("Missing responses API base URL.", notify_title)
    return function() end
  end

  local body = vim.tbl_deep_extend("force", {
    store = false,
    stream = false,
    text = {
      format = { type = "text" },
      verbosity = options.verbosity or default_verbosity,
    },
  }, params or {})

  local cmd = {
    "curl",
    "--silent",
    "--show-error",
    "--fail-with-body",
    "-X",
    "POST",
    base_url .. "responses",
    "-H",
    "Content-Type: application/json",
  }

  if not is_blank(options.authorization) then
    table.insert(cmd, "-H")
    table.insert(cmd, "Authorization: " .. options.authorization)
  end

  table.insert(cmd, "-d")
  table.insert(cmd, vim.json.encode(body))

  local stdout_chunks = {}
  local stderr_chunks = {}

  local function append_chunks(target, data)
    if type(data) ~= "table" then
      return
    end

    for _, chunk in ipairs(data) do
      if type(chunk) == "string" and chunk ~= "" then
        table.insert(target, chunk)
      end
    end
  end

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      append_chunks(stdout_chunks, data)
    end,
    on_stderr = function(_, data)
      append_chunks(stderr_chunks, data)
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        local stdout = table.concat(stdout_chunks, "\n")
        local stderr = table.concat(stderr_chunks, "\n")

        if code ~= 0 then
          handlers.on_error(is_blank(stderr) and stdout or stderr, "Translation API error")
          return
        end

        local ok, decoded = pcall(vim.json.decode, stdout)
        if not ok then
          handlers.on_error(stdout, "Invalid responses API payload")
          return
        end

        if type(decoded) == "table" and decoded.error ~= nil and decoded.error ~= vim.NIL then
          local message = type(decoded.error) == "table" and decoded.error.message or vim.inspect(decoded.error)
          handlers.on_error(message, "Translation API error")
          return
        end

        local chunks = {}
        extract_response_text(decoded, chunks)

        local text = table.concat(chunks)
        if is_blank(text) then
          handlers.on_error(stdout, "Empty responses API output")
          return
        end

        handlers.on_finish(text, "stop")
      end)
    end,
  })

  if job_id <= 0 then
    handlers.on_error("Failed to start translation request.", notify_title)
    return function() end
  end

  return function()
    pcall(vim.fn.jobstop, job_id)
  end
end

function M.build_prompt(filetype)
  if markdown_filetypes[filetype] then
    return table.concat({
      "Translate this Markdown document from English to Chinese.",
      "Preserve all Markdown structure exactly.",
      "Do not translate fenced code blocks, inline code, URLs, or file paths.",
      "Keep headings, lists, tables, links, and emphasis intact.",
      "Output only the translated Markdown.",
    }, " ")
  end

  return table.concat({
    "Translate this text from English to Chinese.",
    "Preserve the original formatting and structure exactly.",
    "Do not translate code blocks, inline code, URLs, or file paths.",
    "Output only the translated text.",
  }, " ")
end

local function build_request_prompt(filetype)
  local config, err = provider_config()
  if not config then
    return nil, err
  end

  if config.wire_api == "responses" then
    return {
      provider = codex_responses_provider,
      options = {
        url = config.base_url,
        authorization = "Bearer " .. config.api_key,
        verbosity = config.verbosity,
      },
      builder = function(input)
        return {
          model = config.model,
          instructions = M.build_prompt(filetype),
          input = input,
        }
      end,
    }
  end

  local openai = require("model.providers.openai")

  return {
    provider = openai,
    options = {
      url = config.base_url,
      authorization = "Bearer " .. config.api_key,
    },
    builder = function(input)
      return {
        model = config.model,
        messages = {
          {
            role = "system",
            content = M.build_prompt(filetype),
          },
          {
            role = "user",
            content = input,
          },
        },
      }
    end,
  }
end

local function next_buffer_name(source_name)
  local base_name = source_name == "" and "[Translation]" or ("[Translation] " .. source_name)
  if vim.fn.bufexists(base_name) == 0 then
    return base_name
  end

  local index = 2
  local candidate = string.format("%s (%d)", base_name, index)
  while vim.fn.bufexists(candidate) == 1 do
    index = index + 1
    candidate = string.format("%s (%d)", base_name, index)
  end

  return candidate
end

local function split_lines(text)
  local lines = vim.split(text, "\n", { plain = true })

  if #lines == 0 then
    return { "" }
  end

  return lines
end

local function translation_path(source_path)
  if is_blank(source_path) then
    return nil
  end

  local directory = vim.fn.fnamemodify(source_path, ":h")
  local filename = vim.fn.fnamemodify(source_path, ":t")
  local stem, extension = filename:match("^(.*)(%.[^./]+)$")

  if stem == nil then
    return directory .. "/" .. filename .. ".zh"
  end

  return directory .. "/" .. stem .. ".zh" .. extension
end

local function confirm_overwrite(target_path)
  if is_blank(target_path) or vim.fn.filereadable(target_path) ~= 1 then
    return true
  end

  local choice = vim.fn.confirm(
    "Translation file already exists:\n" .. target_path .. "\n\nOverwrite it?",
    "&Yes\n&No",
    2
  )

  return choice == 1
end

local function open_result_file(text, filetype, target_path)
  if is_blank(target_path) then
    return false, "Current buffer has no file path. Opened translation in a new buffer instead.", vim.log.levels.WARN
  end

  vim.cmd("vsplit " .. vim.fn.fnameescape(target_path))

  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, split_lines(text))

  if not is_blank(filetype) then
    vim.bo[buf].filetype = filetype
  end

  local ok, err = pcall(vim.cmd, "silent write")
  if not ok then
    return false, "Failed to write translation file: " .. tostring(err), vim.log.levels.ERROR
  end

  vim.notify("Saved translation to " .. target_path, vim.log.levels.INFO, { title = notify_title })
  return true
end

local function open_result_buffer(text, filetype, source_name)
  vim.cmd("vnew")

  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, split_lines(text))
  vim.api.nvim_buf_set_name(buf, next_buffer_name(source_name))

  if not is_blank(filetype) then
    vim.bo[buf].filetype = filetype
  end

  vim.bo[buf].modified = false
end

local function run_translation(input_context, filetype, source_name, output_mode, source_path)
  if is_blank(input_context.input) then
    vim.notify("No text to translate.", vim.log.levels.WARN, { title = notify_title })
    return
  end

  local target_path = output_mode == "file" and translation_path(source_path) or nil
  if output_mode == "file" and not confirm_overwrite(target_path) then
    vim.notify("Translation canceled.", vim.log.levels.INFO, { title = notify_title })
    return
  end

  local prompt, err = build_request_prompt(filetype)
  if not prompt then
    vim.notify(err, vim.log.levels.ERROR, { title = notify_title })
    return
  end

  local provider = require("model.core.provider")

  vim.notify("Translating to Chinese...", vim.log.levels.INFO, { title = notify_title })

  provider.complete(prompt, input_context, function(result)
    vim.schedule(function()
      if is_blank(result) then
        vim.notify("Translation returned empty output.", vim.log.levels.WARN, { title = notify_title })
        return
      end

      local success, message, level
      if output_mode == "file" then
        success, message, level = open_result_file(result, filetype, target_path)
        if not success then
          open_result_buffer(result, filetype, source_name)
        end
      else
        open_result_buffer(result, filetype, source_name)
        success = true
      end

      if message then
        vim.notify(message, level or vim.log.levels.INFO, { title = notify_title })
      end
    end)
  end)
end

local function build_buffer_input_context()
  local input = require("model.core.input")
  local source = input.get_source(false)
  return input.get_input_context(source, "")
end

local function build_line_range_input_context(line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)

  return {
    input = table.concat(lines, "\n"),
    context = {
      args = "",
      filename = vim.fn.expand("%:p"),
    },
  }
end

local function build_visual_input_context()
  local start_pos = vim.fn.getpos("v")
  local stop_pos = vim.fn.getpos(".")

  if start_pos[2] == 0 or stop_pos[2] == 0 then
    start_pos = vim.fn.getpos("'<")
    stop_pos = vim.fn.getpos("'>")
  end

  local start_row = math.min(start_pos[2], stop_pos[2])
  local stop_row = math.max(start_pos[2], stop_pos[2])
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, stop_row, false)

  return {
    input = table.concat(lines, "\n"),
    context = {
      args = "",
      filename = vim.fn.expand("%:p"),
      selection = {
        start = { row = start_row - 1, col = 0 },
        stop = { row = stop_row - 1, col = 0 },
      },
    },
  }
end

function M.translate_selection()
  local filetype = vim.bo.filetype
  local source_name = vim.fn.expand("%:t")
  local source_path = vim.fn.expand("%:p")
  local input_context = build_visual_input_context()
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)

  vim.api.nvim_feedkeys(esc, "x", false)
  vim.schedule(function()
    run_translation(input_context, filetype, source_name, "file", source_path)
  end)
end

function M.translate_buffer()
  run_translation(build_buffer_input_context(), vim.bo.filetype, vim.fn.expand("%:t"), "file", vim.fn.expand("%:p"))
end

function M.translate_command(opts)
  if opts.range ~= 0 then
    run_translation(build_line_range_input_context(opts.line1, opts.line2), vim.bo.filetype, vim.fn.expand("%:t"), "file", vim.fn.expand("%:p"))
    return
  end

  M.translate_buffer()
end

function M.setup()
  vim.api.nvim_create_user_command("ModelTranslate", function(opts)
    M.translate_command(opts)
  end, {
    desc = "Translate selection or buffer to Chinese",
    range = true,
  })

  vim.api.nvim_create_user_command("ModelTranslateBuffer", function()
    M.translate_buffer()
  end, {
    desc = "Translate current buffer to Chinese",
  })
end

return M
