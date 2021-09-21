--package.path = '/usr/local/soft/openresty/lualib/resty/upload.lua;/usr/local/soft/openresty/lualib/resty/mysql.lua;'
--package.path = '/usr/local/soft/openresty/lualib/resty/upload.lua;/usr/local/soft/openresty/lualib/resty/mysql.lua;'

local upload = require "resty.upload"
local mysql = require "resty.mysql"
local template = require "resty.template"
local chunk_size = 4096
local form = upload:new(chunk_size)
local file = nil
local filelen=0
local filepath = nil
form:set_timeout(100000)

local mhost = '192.168.1.4'
local mport = 3306
local muser = 'lua'
local mpwd = 'lua123'
local mdb = 'files'


-- Deal follow warnning:
-- "The character encoding of the HTML document was not declared.
-- The document will render with garbled text in some browser configurations if
-- the document contains characters from outside the US-ASCII range.
-- The character encoding of the page must to be declared in the document or
-- in the transfer protocol. "
--  header add 'Content-type'
ngx.header['Content-type'] = "text/html; charset=utf-8"

-- get filename
local function get_filenames(res)
	ngx.say("\n--function filenames(): res: "..res,'\n')
	local f = ngx.re.match(res,'(.+)filename="(.+)"(.*)')
	if not f then
		print("\n--function filenames(): is nil.\n")
		return
	end
	print('\n------ function filename length: ',table.getn(f),' , type(f):',type(f),'\n')
	print("\n--function: f: "..f[2].."\n")
	--print('\n------ function filename: \n ',filename[0],'   \n',filename[1],'   \n',filename[2],'\n')
	print('\n ------ function filename is Ture.\n')
	return f[2]
end

-- file info into db
local function UPLoadSQL(ss)
	local sql = ss
	local db, err = mysql:new()
	if not db then
		ngx.say("\ndb init error.\n")
		return false
	end
	db:set_timeout(10000)
	
	local ok, err,errno,sqlstate = db:connect({
		host = mhost,
		port = mport,
		user = muser,
		password = mpwd,
		database = mdb
	})
	
	if not ok then
		ngx.say("\nsql ERROR: "..err..",////\n")
		return false
	end
	ngx.say('\ninsert into t_files(fname,url,fcode) value ('..sql..')\n')
	local s,err,errno,sqlstate = db:query('insert into t_files(fname,url,fcode) value ('..sql..')')
	if not s then
		ngx.say("\nsql1do ERROR: "..err..",----\n")
		return false
	end

	return db
end

-- Random Code
local function getCode(f)
	local c = ngx.md5(os.date("%Y-%m-%d %H:%M:%S")..f)
	local s = string.sub(c,1,8)

	print("\n ---function getCode(): ",c," , ",s,"\n")

	return s
end

local osfilepath=ngx.var.filespath
--local i=0
--local j=0
ngx.log(ngx.ERR,'\n----- osfilepath:',osfilepath,'\n')

--print Headers 
local headers = ngx.req.get_headers()
--ngx.say('---- aaaassss : \n',ptable(headers),'---- bbbbcccc\n')

local filename = ''
local u = ''
local fl = 1
local fs = ''

if ngx.var.server_name == "localhost" then
	u = ngx.var.scheme.."://"..ngx.var.host
else
	u = ngx.var.scheme.."://"..ngx.var.server_name
end

while true do
	local typ,res,err = form:read()
	if not typ then
		ngx.say("\nfailed to read-aaa: ",err,'\n')
		return
	end

	--ngx.say('\n----- typ:',typ,'\n')

	if typ == "header" then
		if res[1] ~= "Content-Type" then
			filename = get_filenames(res[2])
			print('\n -----filename -a :',filename,'\n')
			if filename then
				--i=i+1
				filepath = osfilepath..'/'..filename
				--ngx.say("<br>aaaa: <p> "..filepath.." </p> cccc:::<br>")
				file = io.open(filepath,"w+")
				if not file then
					print("<br><p>failed to open file.</p><br>")
					return
				end
				fs = filename
			else
				break
			end
		end
	elseif typ == "body" then
		if file then
			filelen = filelen + tonumber(string.len(res))
			local cm = ngx.md5(res)
			--print("\n----file md5: ",cm,"\n")
			file:write(res)
		else
			print("\n..body:\n  write file error..\n")
			fl = 0
		end
	elseif typ == "part_end" then
		if file then
			print("file upload success.")
		end
	elseif typ == "eof" then
		--ngx.say("\n----- ** i :",i,'\n')
		break
	else
		print("\n..eof: here ..\n")
	end
	--ngx.say("\n----- i :",i,'\n')
	--j = j+1
end

--print("\n--i: ",i,"..j: ",j,"\n")

if file then
	file:close()
	local code = getCode(fs)
	local urlss = "/ab?files="..fs
	local ss = '"'..fs..'","'..urlss..'","'..code..'"'
	print("\n--::ss:: ",ss,"\n")
	local db = UPLoadSQL(ss)
	template.render("uploadsuccess.html",{filenames=fs,codes=code,fileurl=u..urlss})
end

if i == 0 then
	ngx.say("chose one.")
	return
end

