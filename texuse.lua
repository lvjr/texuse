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

function valueExists(tab, val)
  for _, v in ipairs(tab) do
    if v == val then return true end
  end
  return false
end

function tuPrint(msg)
  print("[texuse] " .. msg)
end

function testDistribution()
  -- texlive returns "texmf-dist/web2c/updmap.cfg"
  -- miktex returns nil
  local d = lookup("updmap.cfg")
  --print(d)
  if d then
    return "texlive"
  else
    return "miktex"
  end
end

local dist = testDistribution()
tuPrint("you are using " .. dist)

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

local tutext = ""  -- the json tutext
local tudata = {}  -- the lua object

function main()
  if arg[1] == nil then return end
  if arg[1] == "install" then
    tutext = fileRead(lookup("texuse.json"))
    if tutext then
      --print(tutext)
      tudata = json.tolua(tutext)
      install(arg[2])
    else
      tuPrint("error in reading texuse.json!")
    end
  else
    tuPrint("unknown option " .. arg[1])
  end
end

function install(name)
  local h = name:sub(1,1)
  if h == "\\" then
    local b = name:sub(2)
    installByCommandName(b)
  elseif h == "{" then
    if name:sub(-1) == "}" then
      local b = name:sub(2,-2)
      installByEnvironmentName(b)
    else
      tuPrint("invalid input " .. name)
    end
  else
    installByFileName(name)
  end
end

function installByCommandName(cname)
  --print(cname)
  local fname = getFileNameFromCmdEnvName("cmds", cname)
  if fname then
    installByFileName(fname)
  end
end

function installByEnvironmentName(ename)
  --print(ename)
  local fname = getFileNameFromCmdEnvName("envs", ename)
  if fname then
    installByFileName(fname)
  end
end

function getFileNameFromCmdEnvName(cmdenv, name)
  --print(name)
  for line in tutext:gmatch("(.-)\n[,}]") do
    if line:find('"' .. name .. '"') then
      --print(line)
      local fname, fspec = line:match('"(.-)":(.+)')
      --print(fname, fspec)
      local item = json.tolua(fspec)
      if valueExists(item[cmdenv], name) then
        tuPrint("found package file " .. fname)
        return fname
      end
    end
  end
  tuPrint("could not find any package file with " .. name)
end

local fnlist = {} -- file name list

function installByFileName(fname)
  fnlist = {} -- reset the list
  findDependencies(fname)
  if #fnlist == 0 then
    tuPrint("error in finding package file")
    return
  end
  local pkglist = {}
  for _, fn in ipairs(fnlist) do
    local pkg = findOnePackage(fn)
    --print(fn, pkg)
    if pkg then
      table.insert(pkglist, pkg)
    end
  end
  if not pkglist then
    tuPrint("error in finding package in " .. dist)
    return
  end
  installSomePackages(pkglist)
end

function findDependencies(fname)
  --print(fname)
  if valueExists(fnlist, fname) then return end
  local item = tudata[fname]
  if not item then
    tuPrint("could not find package file " .. fname)
    return
  end
  tuPrint("finding dependencies for " .. fname)
  table.insert(fnlist, fname)
  local deps = item.deps
  if deps then
    for _, dname in ipairs(deps) do
      findDependencies(dname)
    end
  end
end

function findOnePackage(fname)
  local item = tudata[fname]
  if item then
    -- miktex use a different package name
    if dist == "miktex" then
      local mikt = item.mikt
      if mikt then
        return mikt
      end
    end
    -- miktex and texlive share the same package name
    local texl = item.texl
    if texl then
      return texl
    end
  end
end

function installSomePackages(list)
  if dist == "texlive" then
    local p = table.concat(list, " ")
    tuPrint("installing package " .. p)
    os.execute("tlmgr install " .. p)
  else
    for _, p in ipairs(list) do
      tuPrint("installing package " .. p)
      os.execute("miktex packages install " .. p)
    end 
  end
end

main()
