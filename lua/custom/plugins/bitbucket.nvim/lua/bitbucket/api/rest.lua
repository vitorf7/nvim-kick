local M = {}
local utils = require("bitbucket.utils")
local auth = require("bitbucket.auth")
local constants = require("bitbucket.constants")

M.base_url = nil

-- Setup REST API
function M.setup()
  M.base_url = auth.get_base_url()
end

-- Make a REST API call
function M.call(opts, callback)
  opts = opts or {}
  
  local headers, auth_err = auth.get_auth_headers()
  if not headers then
    callback(false, nil, auth_err)
    return
  end
  
  -- Build full URL
  local url = M.base_url .. opts.endpoint
  
  -- Add query parameters
  if opts.params then
    local query_parts = {}
    for key, value in pairs(opts.params) do
      table.insert(query_parts, key .. "=" .. utils.url_encode(tostring(value)))
    end
    if #query_parts > 0 then
      url = url .. "?" .. table.concat(query_parts, "&")
    end
  end
  
  -- Build request body
  local body = nil
  if opts.body then
    body = vim.json.encode(opts.body)
  end
  
  -- Make HTTP request
  utils.http_request(opts.method or "GET", url, body, headers, function(success, response, err)
    if not success then
      -- Handle specific error codes
      if response and response.status == 401 then
        callback(false, nil, "Authentication failed. Please check your credentials.")
      elseif response and response.status == 403 then
        callback(false, nil, "Access forbidden. Check your permissions.")
      elseif response and response.status == 404 then
        callback(false, nil, "Resource not found.")
      elseif response and response.status == 429 then
        callback(false, nil, "Rate limited. Please wait before retrying.")
      else
        callback(false, nil, err or "HTTP request failed")
      end
      return
    end
    
    -- Parse JSON response
    if response.body and response.body ~= "" then
      local ok, data = pcall(vim.json.decode, response.body)
      if ok then
        callback(true, data, nil)
      else
        -- Return raw body if not JSON
        callback(true, { raw = response.body }, nil)
      end
    else
      callback(true, {}, nil)
    end
  end)
end

-- URL encode helper
function M.url_encode(str)
  if str then
    str = str:gsub("([^%w %%-%.%_%~])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = str:gsub(" ", "+")
  end
  return str
end

-- Pagination helper
function M.get_all_pages(endpoint, params, callback)
  local all_results = {}
  local has_more = true
  local page = 1
  
  local function fetch_page()
    if not has_more then
      callback(true, all_results, nil)
      return
    end
    
    local page_params = utils.merge_tables(params or {}, { page = page })
    
    M.call({
      method = "GET",
      endpoint = endpoint,
      params = page_params,
    }, function(success, data, err)
      if not success then
        callback(false, nil, err)
        return
      end
      
      -- Add results
      if data.values then
        for _, item in ipairs(data.values) do
          table.insert(all_results, item)
        end
      end
      
      -- Check for more pages
      if data.next then
        page = page + 1
        has_more = true
        fetch_page()
      else
        has_more = false
        callback(true, all_results, nil)
      end
    end)
  end
  
  fetch_page()
end

return M
