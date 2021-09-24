local mysql = require "resty.mysql"
local request_method = ngx.var.request_method
local args = nil
local code = nil

local mhost = '192.168.1.4'
local mport = 3306
local muser = 'lua'
local mpwd = 'lua123'
local mdb = 'files'

print("\n....here...\n")
if request_method == "GET" then
	args = ngx.req.get_uri_args()
elseif request_method == "POST" then
	ngx.req.read_body()
	args = ngx.req.get_post_args()
end

code = args['ucode']
print("\n..args: ",code,"\n")

local fs = ngx.var.http_referrer
print("\nn...gx.var.referrer: ",fs,"\n")

local function SQL(fpath,code)
	local db,err = mysql:new()
	if not db then
		print("\n...DB Init Error!\n")
		return nil
	end
	db:set_timeout(10000)

	local ok,err,errno,sqlstate = db:connect({
		host = mhost,
		port = mport,
		user = muser,
		password = mpwd,
		database = mdb
	})

	if not ok then
		ngx.say("\nsql ERROR: "..err..",////")
		return nil
	end

	local sql = "select fname from `t_files` where `fcode` = '"..code.."'"
	--ngx.log(ngx.ERR,"SQL sql: ",sql)
	print("\n..SQL sql: "..sql..'\n')
	local res,err,errno,sqlstate = db:query(sql)
	if not res then
		ngx.header["ID_Error"] = "sql_error"
		ngx.log(ngx.ERR, "\n----SQL not record.--------\n")
		return nil
	elseif #(res) > 0 then
		local fname = res[1]["fname"]
		ngx.log(ngx.ERR, "\n-----SQL ROW:-----\n",fname,"\n")
		return fname
	end
end

local osfilepath=ngx.var.filespath
local asf = SQL("aa",code)
--ngx.log(ngx.ERR,"\n---- file asf ----\n", asf,"\n")
print("\n---- file asf : ", asf,"\n")

if asf == nil then
	ngx.header["Content-Type"] = "text/plain"
	print("\nError Code.\n")
	template.render("download-error.html",{filenames=fs,codes=code})
end

print("\n..download: res: ",osfilepath.."/"..asf,"\n")
--local res = ngx.location.capture(osfilepath.."/"..asf)
local res = ngx.location.capture("/localfiles/"..asf)
if res.status ~= 200 then
	ngx.header["Content-Type"] = "text/plain"
	print("\n Not found file.\n")
	return nil
end

ngx.header["Content-Disposition"] = "attachment; filename="..asf
ngx.header["Content-Type"] = "application/octet-stream"
ngx.print(res.body)
