local scnw = 512
local scnh = 512

local image = love.graphics.newCanvas(scnw,scnh)
local asp = scnw/scnh

local aa_samples = 4
local objects = {}

function P3D(x,y,z)
	return {x=x,y=y,z=z}
end

function PDot(a,b)
	return a.x*b.x+a.y*b.y+a.z*b.z
end

function PAdd(a,b)
	return P3D(a.x+b.x,a.y+b.y,a.z+b.z)
end

function PScl(a,s)
	a.x = a.x*s
	a.y = a.y*s
	a.z = a.z*s
end

function PSub(a,b)
	return P3D(a.x-b.x,a.y-b.y,a.z-b.z)
end

function ColorPixel(x,y,r,g,b,a)
	love.graphics.setColor(r,g,b,a)
	love.graphics.points(x,y)
end

function RandFract()
	return math.random(0,10)/10
end

function RandFractSign()
	return 2*RandFract()-1
end

function RandPointInSphere()
	local p = P3D(0,0,0)
	while 1 do
		p.x = RandFractSign()
		p.y = RandFractSign()
		p.z = RandFractSign()
		if PDot(p,p)<1 then
			return p
		end
	end
	--[[
	local theta = RandFract()*2*math.pi
	local z = RandFractSign()
	local r = math.sqrt(1-z*z)
	return P3D(r*math.cos(theta),r*math.sin(theta),z)
	]]
end

function RayHitSphere(ro,rd,o,r,tmin,tmax)
	local oc = PSub(ro,o)
	local a = PDot(rd,rd)
	local b = 2*PDot(oc,rd)
	local c = PDot(oc,oc)-r*r
	local d = b*b-4*a*c
	if d<=0 then
		return
	end
	local d2 = math.sqrt(d)
	a = 1/(2*a)
	local root = (-b-d2)*a
	if root>1e-3 and root<math.huge then
		return root
	end
	root = (-b+d2)*a
	if root>1e-3 and root<math.huge then
		return root
	end
end

function RayHitPlane(ro,rd,p,n)
	local d = PDot(p,n)
	local denom = PDot(n,rd)
	if math.abs(denom)<1e-3 then
		return
	end
	local t = (PDot(n,ro)+d)/denom
	if t<=0 then
		return
	end
	return t
end

function AddPlane(x,y,z,nx,ny,nz)
	table.insert(objects, {
		p = P3D(x,y,z),
		n = P3D(nx,ny,nz),
		HitFunc = function(self,ro,rd,tmin)
			local t = RayHitPlane(ro,rd,self.p,self.n)
			if t and t<tmin then
				local rec = {}
				rec.t = t
				rec.p = P3D(rd.x,rd.y,rd.z)
				PScl(rec.p,t)
				rec.p = PAdd(rec.p,ro)
				rec.n = self.n
				return rec
			end
		end
	})
end

function AddSphere(x,y,z,radius)
	table.insert(objects, {
		p = P3D(x,y,z),
		r = radius,
		HitFunc = function(self,ro,rd,tmin)
			local t = RayHitSphere(ro,rd,self.p,self.r)
			if t and t<tmin then
				local rec = {}
				rec.t = t
				rec.p = P3D(rd.x,rd.y,rd.z)
				PScl(rec.p,t)
				rec.p = PAdd(rec.p,ro)				
				rec.n = PSub(rec.p,self.p)
				--awfulness
				PScl(rec.n, 1/self.r)		
				return rec
			end
		end
	})
end

function Ray(ro,rd,depth)
	if depth<=0 then
		return P3D(0,0,0)
	end
	local t = math.huge
	local rec
	for k,obj in pairs(objects) do
		local r = obj.HitFunc(obj,ro,rd,t)
		if r then
			t = r.t
			rec = r
		end
	end
	if rec then
		local d = RandPointInSphere()
		local s = PAdd(rec.p,PAdd(rec.n,d))
		local col = Ray(rec.p,PSub(s,rec.p),depth-1,false)
		PScl(col,0.5)
		return col
	end
	if 1 then return P3D(1,1,1) end
	t = 0.5*(rd.y)+1
	local c1 = P3D(1,1,1)
	local c2 = P3D(0.5,0.7,1)
	PScl(c1,1-t)
	PScl(c2,t)
	return PAdd(c1,c2)
end

AddSphere(0,0,-30, 10)
--AddSphere(0,-1010,-30, 1000)
AddPlane(0,-10,0, 0,1,0)

love.window.setMode(scnw,scnh)
love.graphics.setCanvas(image)
--love.graphics.setBlendMode("replace","alphamultiply")
local rayorigin = P3D(0,0,0)
local raydir = P3D(0,0,0)

function Clamp(n,min,max)
	if n<min then
		return min
	elseif n>max then
		return max
	end
	return n
end

for i=0,scnw-1 do
for j=0,scnh-1 do
	local ar,ag,ab = 0,0,0
	for k=1,aa_samples do
		local u = (2*((i+RandFract())/(scnw-1))-1)*asp
		local v = -(2*((j+RandFract())/(scnh-1))-1)
		raydir.x = u
		raydir.y = v
		raydir.z = -1
		local col = Ray(rayorigin,raydir,10)
		ar = ar+col.x
		ag = ag+col.y
		ab = ab+col.z
	end
	ar = math.sqrt(ar/aa_samples)
	ag = math.sqrt(ag/aa_samples)
	ab = math.sqrt(ab/aa_samples)
	--ar = ar/aa_samples
	--ag = ag/aa_samples
	--ab = ab/aa_samples
	ColorPixel(i,j,Clamp(ar,0,1),Clamp(ag,0,1),Clamp(ab,0,1))
end
end

love.graphics.reset()

function love.draw()
	love.graphics.draw(image)
end
