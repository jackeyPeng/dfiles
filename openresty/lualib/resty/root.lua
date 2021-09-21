local request_method = ngx.var.request_method
local template = require "resty.template"
local args = nil
local file = nil



if request_method == "GET" then
    args = ngx.req.get_uri_args()
elseif request_method == "POST" then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

file = args['files']

template.render("wb.html",{files=file})

