local mysql = require "resty.mysql"
local request_method = ngx.var.request_method
local arg = nil

local mhost = '192.168.1.2'
local mport = 3306
local muser = 'lua'
local mpwd = 'lua123'
local mdb = 'files'

function SQL(fpath,code)
	local db,err = mysql:new()
	if not db then
		ngx.say("DB Init Error!")
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
		ngx.say("sql ERROR: "..err..",////")
		return nil
	end

