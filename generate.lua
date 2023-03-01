#!/usr/bin/env texlua

-- Description: Install TeX packages and their dependencies
-- Copyright: 2023 (c) Jianrui Lyu <tolvjr@163.com>
-- Repository: https://github.com/lvjr/texuse
-- License: GNU General Public License v3.0

local tuversion = "2023A"
local tudate = "2023-03-01"

local lookup = kpse.lookup
kpse.set_program_name("kpsewhich")

-- we need utilities.json.tostring and utilities.json.tolua
require(lookup("lualibs.lua"))
local json = utilities.json

local tlpkgdb = "download/texlive.tlpdb"
local mtpkgdb = "download/package-manifests.ini"
local filedbpath = "download/completion/"

local showdbg = false

function dbgPrint(dbg)
  if showdbg then print(dbg) end
end

function valueExists(tab, val)
  for _, v in ipairs(tab) do
    if v == val then return true end
  end
  return false
end

function fileRead(input)
  local f = io.open(input, "rb")
  local text
  if f then -- file exists and is readable
    text = f:read("*all")
    f:close()
    --print(#text)
    return text
  end
  -- return nil if file doesn't exists or isn't readable
end

function fileWrite(text, output)
  -- using "wb" keeps unix eol characters
  f = io.open(output, "wb")
  f:write(text)
  f:close()
end

local tudata = {}

function main()
  print("Processing texlive and texstudio package database...")
  local text = fileRead(tlpkgdb)
  extractLiveFiles(text)
  print("Processing miktex package database...")
  local text = fileRead(mtpkgdb)
  checkMiKTeXFiles(text)
  writeJson()
end

function extractLiveFiles(text)
  text:gsub("name (.-)\n(.-)\n\n", findLiveFiles)
end

function findLiveFiles(name, desc)
  -- ignore binary packages
  -- also ignore latex-dev packages
  if name:find("%.") or name:find("^latex%-[%a]-%-dev") then
    --print(name)
    return
  end
  -- ignore package files in doc folder
  desc = desc:match("\nrunfiles .+") or ""
  for base, ext in desc:gmatch("/([%a%d%-]+)%.([%a%d]+)\n") do
    if ext == "sty" or ext == "cls" then
      dbgPrint(base .. "." .. ext)
      local item = findFileDepCmdEnv(base, ext) or {}
      dbgPrint(item)
      item.texl = name -- add texlive package name
      tudata[base .. "." .. ext] = item
    end
  end
end

function findFileDepCmdEnv(base, ext)
  local cwlfile
  if ext == "sty" then
    cwlfile = filedbpath .. base .. ".cwl"
  else -- latex class
    cwlfile = filedbpath .. "class-" .. base .. ".cwl"
  end
  dbgPrint(cwlfile)
  local cwl = fileRead(cwlfile)
  --dbgPrint(cwl)
  if cwl then
    local item = extractFileData(cwl)
    dbgPrint(item)
    return item
  else  
    --dbgPrint("can not find " .. cwlfile)
  end
end

function extractFileData(cwl)
  -- the cwl files have different eol characters
  local deps = {}
  for d in cwl:gmatch("\n#include:(.-)[\r\n]") do
    --dbgPrint(d)
    n = d:match("^class-(.+)$")
    if n then
      insertNewValue(deps, n .. ".cls")
    else
      insertNewValue(deps, d .. ".sty")
    end
  end
  local envs = {}
  for b, e in cwl:gmatch("\n\\begin{(.-)}.-\n\\end{(.-)}") do
    if b == e then
      --dbgPrint("{" .. e .. "}")
      table.insert(envs, e)
    end
  end
  local cmds = {}
  for c in cwl:gmatch("\n\\(%a+)") do
    if c ~= "begin" and c ~= "end" then
      --dbgPrint("\\" .. c)
      if not valueExists(cmds, c) then
        table.insert(cmds, c)
      end
    end
  end
  --return {deps, envs, cmds}
  return {deps = deps, envs = envs, cmds = cmds}
end

function insertNewValue(tbl, val)
  if not valueExists(tbl, val) then
    table.insert(tbl, val)
  end
end

function checkMiKTeXFiles(text)
  text:gsub("%[(.-)%]\n(.-)\n\n", findMikFiles)
end

function findMikFiles(name, desc)
  --print(name)
  -- ignore package files in source or doc folders
  -- also ignore latex-dev packages
  if name:find("_") or name:find("^latex%-[%a]-%-dev")then
    --print(name)
    return
  end
  for base, ext in desc:gmatch("/([%a%d%-]+)%.([%a%d]+)\n") do
    if ext == "sty" or ext == "cls" then
      dbgPrint(base .. "." .. ext)
      local item = tudata[base .. "." .. ext]
      if item then
        dbgPrint(item)
        if item.texl ~= name then
          -- texlive and miktex use different package names
          print(base .. "." .. ext ..
               ": texlive -> " .. item.texl .. "; miktex -> " .. name)
          -- add miktex package name
          tudata[base .. "." .. ext].mikt = name
          --item.mikt = name
        end
      else
        -- ignore miktex-only packages for now
        dbgPrint(base .. "." .. ext)
        return
      end
    end
  end
end

function writeJson()
  print("Writing json database to file...")
  local tbl1 = {}
  for k, v in pairs(tudata) do
    table.insert(tbl1, {k, v})
  end
  table.sort(tbl1, function(a, b)
    if a[1] < b[1] then return true end
  end)
  local tbl2 = {}
  for _, v in ipairs(tbl1) do
    local item = '"' .. v[1] .. '":' .. json.tostring(v[2])
    table.insert(tbl2, item)
  end
  local text = "{\n" .. table.concat(tbl2, "\n,\n") .. "\n}"
  fileWrite(text, "texuse.json")
end

main()
