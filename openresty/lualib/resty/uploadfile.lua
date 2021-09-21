local upload = require "resty.upload"
local cjson = require "cjson"
local chunk_size = 4096
local form,err = upload:new(chunk_size)

if not form then
	ngx.log(ngx.ERR, "\nfailed to new upload: ", err,"\n")
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

form:set_timeout(10000)

string.split = function(s,p)
	local rt = {}
	string.gsub(s,'[^'..p..']+',function(w) table.insert(rt,w) end)
	return rt
end

string.trim = function(s)
	return (s:gsub("^%s*(.-)%s*$","$1"))
end

local saveRootPath = ngx.var.store_dir
local fileToSave
local ret_save = nil

while true do
	local typ,res,err = form:read()
	if not typ then
		ngx.say("\nfailed to read: ",err)
		return
	end

	if typ == "header" then
		local key = res[1]
		local value = res[2]
		if key == "Content-Disposition"  then
			local kvlist = string.split(value,";")
			for _, kv in ipairs(kvlist) do
				local seg = string.trim(kv)
				if seg:find("filename") then
					local kvfile =string.split(seg, "=")
					local filename = string.sub(kvfile[2],2,-2)
					if filename then
						fileToSave = io.open(saveRootPath..filename,"w+")
						if not fileToSave then
							ngx.say("\nfailed to open file ",filename, "\n")
							return
						end
						break
					end
				end
			end
		end
	elseif typ == "body" then
		if fileToSave then
			fileToSave:write(res)
		end
	elseif typ == "part_end" then
		if fileToSave then
			fileToSave:close()
			fileToSave = nil
		end
	elseif typ == "eof" then
		break
	else
		ngx.log(ngx.INFO,"do other things\n")
	end
end

if ret_save then
	ngx.say("save file ok.")
end
