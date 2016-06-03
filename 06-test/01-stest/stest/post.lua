
--[[

Author:
   - Jorge Couchet <jorge.couchet@gmail.com>

--]]

require "io"
local contents = ""
local file = io.open("test_files/test.txt", "r" )
if (file) then
	-- read all contents of file into a string
        contents = file:read("*all")
        file:close()

	wrk.method = "POST"
	wrk.body   = contents
	wrk.headers["Content-Type"] = "multipart/form-data; boundary=---------------------------126474506989943511588532701"
end
