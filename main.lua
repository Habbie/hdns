#!/usr/bin/env luajit
local socket = require'socket'
local bit = require'bit'
local sock = socket.udp()
sock:setsockname('*', 5300)

local data, ip, port = sock:receivefrom()
print(type(data))

local req = {}
local function bytereader(data)
	local offset = 1
	local function getbyte()
		offset = offset + 1
		return data:byte(offset -1)
	end
	local function getword()
		return getbyte() * 256 + getbyte()
	end
	return {
		getbyte = getbyte,
		getword = getword
	}
end

local function bitreader(data, size)
	-- size is a multiple of 8
	print("bitreader data", data, size)
	local offset = size - 1
	local function getbits(n)
		local res = 0
		local resoffset = n-1
		while resoffset >= 0 do
			assert("ran out of bits", offset>=0)
			print("offset", offset)
			local mask = bit.lshift(1, offset)
			local maskedbit = bit.band(data, mask)
			print("maskedbit", maskedbit)
			local maskedbitshifted = bit.rshift(maskedbit, offset)
			print("maskedbitshifted", maskedbitshifted)
			res = bit.bor(res, bit.lshift(maskedbitshifted, resoffset))
			resoffset = resoffset - 1
			offset = offset - 1
		end
		return res
	end
	return {
		getbits = getbits
	}
end

local byr = bytereader(data)
req.id = byr.getword()
local flags = byr.getword()
local _

local bir = bitreader(flags, 16)
req.qr = bir.getbits(1)
req.opcode = bir.getbits(4)
req.aa = bir.getbits(1)
req.tc = bir.getbits(1)
req.rd = bir.getbits(1)
req.ra = bir.getbits(1)
req.z = bir.getbits(1)
req.ad = bir.getbits(1)
req.cd = bir.getbits(1)
req.rcode = bir.getbits(4)
req.qdcount = byr.getword()
req.ancount = byr.getword()
req.nscount = byr.getword()
req.arcount = byr.getword()

for k,v in pairs(req) do print(k,v) end