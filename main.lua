#!/usr/bin/env luajit
local socket = require'socket'
local bit = require'bit'
local inspect = require'inspect'

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
	local function getstring(n)
		print("#data", #data)
		print("offset, n, offset + n -1", offset, n, offset+n -1)
		assert(#data >= offset + n -1, "not enough bytes for getstring")
		local ret = data:sub(offset, offset + n -1)
		offset = offset + n
		return ret
	end
	local function getword()
		return getbyte() * 256 + getbyte()
	end
	return {
		getbyte = getbyte,
		getstring = getstring,
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
			assert(offset>=0, "ran out of bits")
			local mask = bit.lshift(1, offset)
			local maskedbit = bit.band(data, mask)
			local maskedbitshifted = bit.rshift(maskedbit, offset)
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

local function readname(byr)
	local namelen = 0
	local res = {}
	while true do
		local labellen = byr.getbyte()
		-- print("labellen", labellen)
		if labellen == 0 then
			break
		end
		-- FIXME handle compression
		assert(labellen <= 63, "label length over 63")
		local label = byr.getstring(labellen)
		-- print("label", label)
		table.insert(res, 1, label)
		namelen = namelen + 1 + labellen
		assert(namelen < 255, "name too long")
	end
	return res
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

req.qd = {}

for i=1, req.qdcount do
	table.insert(req.qd, {
		qname = readname(byr),
		qtype = byr.getword(),
		qclass = byr.getword()
	})
end

local function getrrs(byr, count)
	local ret = {}
	for i=1, count do
		local _ret = {
			qname = readname(byr),
			qtype = byr.getword(),
			qclass = byr.getword(),
			ttl = byr.getword() * 65536 + byr.getword(),
			rdlength = byr.getword()
		}
		_ret.rdata = byr.getstring(_ret.rdlength)
		print("#rdata", #_ret.rdata)
		table.insert(ret, _ret)
	end
	return ret
end

req.an = getrrs(byr, req.ancount)
req.ns= getrrs(byr, req.nscount)
req.ar = getrrs(byr, req.arcount)

print(inspect(req))


