-- Tiny http server
local http = {}

-- parse req
http.req = function(req)
	local err = nil
	local REQ = {query={}, head={}}
	local _, _, method, path, vars = string.find(req, "^([A-Z]+) (.+)%?(.+) HTTP");

	if ( method == nil ) then
		local _, _, method, path = string.find(req, "(^[A-Z]+) (.+) HTTP")
	else
		-- разобрать vars
		for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
			REQ.query[k] = v
		end
	end
	-- @todo: parse headers
	-- @todo: parse body
	-- @todo: user auth

	REQ.path = path
	REQ.method = method

	return err, REQ
end

function http.route( socket, REQ, fn )
	if file.open(REQ.method .. "_" .. REQ.path ..'lc') then
		file.close()
		-- @att: добавить в вывод
		-- client:send("HTTP/1.1 200 OK\r\n");
		-- client:send("Content-type: text/html\r\n");
		return dofile(REQ.method .. "_" .. REQ.path ..'lc')(socket, REQ, fn)
	else
		socket:send("HTTP/1.1 404 OK\r\n")
		fn()
	end
end

function http.done( socket )
	socket:send("Connection: close\r\n\r\n");
	socket:close();
	collectgarbage("collect");
end

function http.request( socket, req )
	local err, REQ = http.req(req)
	if err ~= nil then
		socket:send("HTTP/1.1 500 OK\r\n")
		http.done( socket )
	else
		http.route( socket, REQ , function() http.done(socket) end)
	end
end

function http.init( port )
	--  timeout 100ms
	srv = net.createServer( net.TCP, 100)
	srv:listen( port, function(socket) socket:on("receive", http.request) end)
end

return http