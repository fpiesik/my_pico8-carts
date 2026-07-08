pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

function _init()
	--make an index of the game states
	for k,v in pairs(gsts) do
		gsidx[v]=k
	end
	if(gst==gsidx["hear"])hear:init()
	if(gst==gsidx["play"])play:init()
end

function _draw()
 cls(1)
	map()
	if gst==gsidx["menu"] then
		menu:draw()
	elseif gst==gsidx["intro"] then
		intro:draw()
	elseif gst==gsidx["hear"] then
		hear:draw()
	elseif gst==gsidx["play"] then
		play:draw()
	end
end

function _update60()      
	if (gst==gsidx["hear"] or gst==gsidx["play"]) and btn(4) and btn(5) then
		gst=gsidx["menu"]
		sfx(-1)
		music(-1)
		return
	end
	if gst==gsidx["menu"] then
		menu:upd()
	elseif gst==gsidx["intro"] then
		intro:upd()
	elseif gst==gsidx["hear"] then
		hear:upd()
	elseif gst==gsidx["play"] then
		play:upd()
	end
end


gsts={"menu","intro","play","hear"} --game states
gst=1 --actual game state
gsidx={}
a_bt=2 --active beat
bidx=0 --beat index (current note)
spd=60 --speed
vism=1 --visualisation mode: circle and/or score btsfx
btsfx=8 --beat sfx
btch=0 --beat audio channel 
metrosfx=9 --metronome sfx
metroch=1 --metronome audio channel
essfx=0 --es sfx
dumsfx=1 --dum sfx
taksfx=2 --tak sfx
bpm=90

lvld={ --levels of difficulty
	syl=0, -- syllables
	nts=0, --notes
	idxc=1, -- beat position circle
	eidxc=1, 
	idxs=1,-- beat position score
	eidxs=1,
	np=1, --number of pulses
	nm=1, --name of the rhythm
	drani=1, -- animation of the drumming
 	hnd=1 -- hands
}

--colors
clrs={ 
	bck=1, --background
	btn=9, --beat name
	syl={5,9,11}, --syllables
	scr={3,8}, --score color
	btpos=15, --beat position 
	epos=8, --edit position
	tsig=3, --time signature
	spd=3, --speed (bpm)
	posn=4 
}

--score
scr={
 hit=0,
 mss=0
}

--beat order
btord={"stop","maksum","ayub","beledi","saidi","saudi","masmudi","melfuf","chiftetelli","elzaffa","karshilama","rumba","frank"}

beats={
 stop={0},
 maksum={1,2,0,2,1,0,2,0},
 ayub={1,0,1,2},
 beledi={1,1,0,2,1,0,2,0},
	saidi={1,2,0,1,1,0,2,0},
 saudi={1,0,0,1,0,0,2,0},
 masmudi={1,1,0,0,1,0,0,0},
 melfuf={1,0,0,2,0,0,2,0},
 chiftetelli={1,0,2,2,0,2,2,0,1,0,1,0,2,0,0,0},
 elzaffa={1,0,2,2,2,0,2,0,1,0,2,2,0,0,0},
 karshilama={1,0,2,0,1,0,2,2,2},
 rumba={1,0,0,0,1,0,2,0},
 frank={1,1,2,1,1,0,2,0}
}

--syllables
syl={"es","dum","tak"}
sylc={2,3,9}

--title screen
menu={
	x = 40,
	y = 60,
	spc = 7,
	idx = 1,
	opts = {"play","hear"},
	draw=function(s)
		for i = 1, #s.opts do
			print(s.opts[i],s.x,s.y+i*s.spc,7)
			--if(i==s.idx)rect(s.x-2,s.y+i*s.spc-2,s.x+30,s.y+i*s.spc+6,7)
			if(i==s.idx)print("➡️",s.x-10,s.y+i*s.spc,7)
		end
  spr(128,0,0,16,4)
  print("❎/c start",44,114,10)
	end,
	upd=function(s)
		if btnp(3) then
			s.idx+=1
			if(s.idx>#s.opts)s.idx=#s.opts
		end
		if btnp(2) then
			s.idx-=1
			if(s.idx<1)s.idx=1
		end
		if btnp(4) then
			intro.mode=s.opts[s.idx]
			gst=gsidx["intro"]
			sfx(-1)
			music(-1)
		end
	end
}

--mode explanation screen
intro={
	mode="play",
	draw=function(s)
		spr(128,0,0,16,4)
		print(s.mode.." mode",20,40,9)
		if s.mode=="play" then
			print("play the rhythm",20,50,7)
			print("the circle shows you how.",20,58,7)
			print("⬅️ tak   ➡️ dum",20,74,3)
			print("⬆️ ⬇️ tempo",20,84,3)
			print("🅾️/x ❎/c rhythm",20,94,3)
		else
			print("hear the rhythm",20,50,7)
			print("and build it",20,58,7)
			print("⬅️ ➡️ position",20,74,3)
			print("⬆️ ⬇️ place",20,84,3)
			print("🅾️/x check",20,94,3)
		end
		print("❎/c start",20,114,9)
	end,
	upd=function(s)
		if btnp(4) then
			gst=gsidx[s.mode]
			if(gst==gsidx["hear"])hear:init()
			if(gst==gsidx["play"])play:init()
		end
		if btnp(5) then
			gst=gsidx["menu"]
		end
	end
}

--transcribe rhythms screen
hear={
	ansbt={},
	qstbt={},
	crr={0,0}, --correctness
	btl=0, --beat length
	abtl=0, --answer beat length
	mxbtl=32,
	
	init=function(self)
		self.correct=0
		a_bt=flr(rnd(#btord))+1
		self.btl=#beats[btord[a_bt]]
		self.abtl=#beats[btord[a_bt]]
		lvld.syl=0
		--self.ansbt=beats[btord[a_bt]]
		for i=1,self.mxbtl do 
			self.ansbt[i]=0
		end
		for i=1,self.btl do 
			self.qstbt[i]=beats[btord[a_bt]][i]
		end
		set_spd(btsfx,spd)
		mk_beat(a_bt) 
		bcirc.btl = self.btl
		bcirc.abtl = self.abtl
		bcirc.ansbt = self.ansbt
		bcirc.qstbt = self.qstbt
	end,

	upd=function(self)
	 	if btnp(1) then 
			bidx=bidx+1
   			if bidx>self.abtl-1 then bidx=0 
			end
		end
		if btnp(0) then 
			bidx=bidx-1 
   			if bidx<0 then bidx=self.abtl-1
			end
		end
		if btnp(3) then
			self.ansbt[bidx+1]=self.ansbt[bidx+1]+1
			if self.ansbt[bidx+1]>2 then self.ansbt[bidx+1]=0
			end
		end
		if btnp(2) then
	 		self.ansbt[bidx+1]=self.ansbt[bidx+1]-1
	 		if self.ansbt[bidx+1]<0 then self.ansbt[bidx+1]=2
			end
		end
		if btnp(4) then
	 		self:chck()
	 		if self.correct==1 then self:init()
			end
		end
		if btn(5) and btnp(1) then
			self.abtl=self.abtl+1
	 		if self.abtl>24 then self.abtl=24
			end
		end
		if btn(5) and btnp(0) then
	 		self.abtl=self.abtl-1
	 		if self.abtl<0 then self.abtl=0
			end
		end
		if btn(5) and btnp(3) then
			spd=spd+1
	 		if spd>100 then pd=100
			end
  			set_spd(btsfx,spd)
		end
		if btn(5) and btnp(2) then
			spd=spd-1
			if spd<5 then spd=5
			end
			set_spd(btsfx,spd)
		end
		bcirc.btl = self.btl
		bcirc.abtl = self.abtl
		bcirc.ansbt = self.ansbt
		bcirc.qstbt = self.qstbt
	end,

	draw=function(self)
		print(btord[a_bt],5,5,clrs.btn)
		--print(stat(50))
		bcirc:draw()
		if(vism==2)bscore:draw()
		
		print(scr.hit,109,5,clrs.scr[1])
		print(scr.mss,117,5,clrs.scr[2])
		
		print("bpm:",5,12,clrs.spd)	
		print(flr(spd2bpm(spd)),21,12,clrs.spd)	

		if(stat(50+btch)<=8)print(stat(50+btch)+1, 109, 120,clrs.tsig)
		if(stat(50+btch)>8)print(stat(50+btch)+1, 105, 120,clrs.tsig)
		print("/", 113, 120,clrs.tsig)
		print(self.btl, 117, 120,clrs.tsig)
	end,

	chck=function(self)
		self.crr[2]=1
		for i=1,self.btl do
			if(self.ansbt[i]!=self.qstbt[i]) self.crr[2]=0
		end
		if (self.btl == self.abtl) self.crr[1]=1
		if self.crr[2] == 1 and self.crr[1] == 1 then
			scr.hit+=1
			spr(5,60,60,4,4)
			self:init()
		else
			scr.mss+=1
		end
	end
}

play={
	ansbt={},
	qstbt={},
	crr={0,0}, --correctness
	btl=0, --beat length
	abtl=0, --answer beat length
	mxbtl=32,
 qbang={},
	
	init=function(self)
		self.correct=0
		--a_bt=flr(rnd(#btord))+1
		self.btl=#beats[btord[a_bt]]
		lvld.syl=1
  
		--self.ansbt=beats[btord[a_bt]]
		for i=1,self.mxbtl do 
			self.ansbt[i]=0
		end
		for i=1,self.btl do 
			self.qstbt[i]=beats[btord[a_bt]][i]
   self.qbang[i]= (i-1)/self.btl
		end 
  --setup music first, then the
  --metronome clock. otherwise
  --music() can replace the sfx on
  --metroch and the visual clock
  --will follow the song pattern
  --instead of the rhythm length.
  for i=10,30 do
   set_spd(i, spd)
  end
  music()
  --setup metronome
  set_spd(metrosfx, spd)
  set_loop(metrosfx,0,self.btl)
  sfx(metrosfx,metroch)

		plcirc.btl = self.btl
		plcirc.abtl = self.abtl
		plcirc.ansbt = self.ansbt
		plcirc.qstbt = self.qstbt
  plcirc.plinput = {}
  plcirc.qbang = self.qbang
  plcirc.dumtaks = 0
  for i=1,self.btl do
   if beats[btord[a_bt]][i]>0 then 
    plcirc.dumtaks += 1
   end
  end
  plcirc.maxhitdisp=plcirc.dumtaks
  plcirc.plang=0
  plcirc.mstat=0
  plcirc.lmstat=-1
  plcirc.mfrm=0
  plcirc.nrounds=0
	end,

	upd=function(self)
	 	if btnp(5) then 
    a_bt=a_bt+1
    if a_bt>#btord then a_bt=1 end
    self:init()
		end
		if btnp(4) then 
			a_bt=a_bt-1 
   if a_bt<=0 then a_bt=#btord end
   self:init()
		end
  if btnp(1) then 
   sfx(dumsfx,btch)
   add(plcirc.plinput, {plcirc.plang, 1})
   plcirc.rhd = 1
  end
  if btnp(0) then 
   sfx(taksfx,btch)
   add(plcirc.plinput, {plcirc.plang, 2})
   plcirc.lhd = 1
  end

		if btnp(3) then
			spd=spd+1
	 		if spd>100 then pd=100
			end
  			set_spd(btsfx,spd)
     self:init()
		end
		if btnp(2) then
			spd=spd-1
			if spd<5 then spd=5 end
			set_spd(btsfx,spd)
   self:init()
		end
		plcirc.btl = self.btl
		plcirc.abtl = self.abtl
		plcirc.ansbt = self.ansbt
		plcirc.qstbt = self.qstbt
  --plcirc.maxhitdisp = self.btl
	end,

	draw=function(self)
  print(a_bt,2,2,clrs.btn)
		print(btord[a_bt],10,2,clrs.btn)
		--print(stat(50))
		plcirc:draw()
		if(vism==2)bscore:draw()
		
		print("bpm:",2,10,clrs.spd)	
		print(flr(spd2bpm(spd)),20,10,clrs.spd)	

		if(stat(50+metroch)<=8)print(stat(50+metroch)+1, 109, 120,clrs.tsig)
		if(stat(50+metroch)>8)print(stat(50+metroch)+1, 105, 120,clrs.tsig)
		print("/", 113, 120,clrs.tsig)
		print(self.btl, 117, 120,clrs.tsig)
	end,

	chck=function(self)
		self.crr[2]=1
		for i=1,self.btl do
			if(self.ansbt[i]!=self.qstbt[i]) self.crr[2]=0
		end
		if (self.btl == self.abtl) self.crr[1]=1
		if self.crr[2] == 1 and self.crr[1] == 1 then
			scr.hit+=1
			spr(5,60,60,4,4)
			self:init()
		else
			scr.mss+=1
		end
	end
}

bcirc={
 	center_x = 63,
	center_y = 54,
	radius = 38,
	btnmb = 0,
	btl = 0,
	qstbt = {},
	ansbt = {},
	i=1,
	stat=0,
	lstat=0,
 	draw=function(self)
		self.btnmb = a_bt
		--self.btl = play.abtl
		self.stat=stat(50+btch)
		if(vism==1) then
		 	self.center_x = 63
		 	self.center_y = 66
  			self.radius = 50
		end
	 	if(vism==2) then
			self.center_x = 63
			self.center_y = 54
			self.radius = 38
	 	end
		self.btnmb = a_bt
	 	
		local note
	 
	 	--spr(0,self.center_x-32,self.center_y-32,8,8)
	 	for i=1, self.btl do
			if(lvld.syl==1)note=self.qstbt[i]
   			if(lvld.syl==0)note=self.ansbt[i]
   			local angle = (i-1)/self.btl
			local x = self.center_x + self.radius * sin(angle+0.5)
   			local y = self.center_y + self.radius * cos(angle+0.5)
			local xi = self.center_x + (self.radius-13) * sin(angle+0.5)
   			local yi = self.center_y + (self.radius-13) * cos(angle+0.5)
			if(note==0)color=clrs.syl[1]
			if(note==1)color=clrs.syl[2]
			if(note==2)color=clrs.syl[3]
			if(bidx+1==i and lvld.eidxc==1) then
				circ(x,y,8,clrs.epos)
			end
			if(self.stat+1==i and lvld.idxc==1) then
				circ(x,y,9,clrs.btpos)
			elseif(self.stat+1==1 and lvld.idxc==0 and i==1) then
				circ(x,y,9,clrs.btpos)
			end
			if note==0 then
				x-=3
				y-=2
			end
			if note==1 then
				x -= 5
				y -= 2
			end
			if note==2 then
				x -= 5
				y -= 2
   			end
   			print(syl[note+1], x, y,color)
			print(i, xi - 1, yi - 2, clrs.posn)
	 	end
		self:hands()
	end,
	
	rhd = 0,
	lhd = 0,
	rhpos = {-1},	
	lhpos = {},
	hands=function(self)	 
		local nt = 0
		local spdhit =2
		local spdbck =5
		local rhst = {self.center_x-5,self.center_y-5}
		local lhst = {self.center_x-32,self.center_y+5}
		local rhmov = {-5,-5}
		local lhmov = {4,-4}
		if(lvld.hnd == 0)nt = self.ansbt[self.stat+1]
		if(lvld.hnd == 1)nt = self.qstbt[self.stat+1]
		if(self.rhpos[1]==-1) then 
		self.rhpos[1]=rhst[1]
		self.rhpos[2]=rhst[2]
		self.lhpos[1]=lhst[1]
		self.lhpos[2]=lhst[2]
		end

		if(self.rhpos[1]==rhst[1])self.rhd = 0
		if(self.lhpos[1]==lhst[1])self.lhd = 0

		if self.lstat!=self.stat then
			if (nt == 1) self.rhd = 1
			if (nt == 2) self.lhd = 1
			self.lstat=self.stat
		end

		if btn(4) then self.rhd = 1 end 
		if btn(5) then self.lhd = 1 end 

		if(self.rhpos[1]<=rhst[1]+rhmov[1])self.rhd = -1
		if(self.lhpos[1]>=lhst[1]+lhmov[1])self.lhd = -1

		if self.rhd==1 then 
			self.rhpos[1]+=rhmov[1]
			self.rhpos[2]+=rhmov[2]
		elseif(self.rhd==-1) then 
			self.rhpos[1] += 1
			self.rhpos[2] += 1
		end
		if self.lhd==1 then 
			self.lhpos[1]+=lhmov[1]
			self.lhpos[2]+=lhmov[2]
		elseif(self.lhd== -1) then 
			self.lhpos[1] -= 1
			self.lhpos[2] += 1
		end
		spr(0,self.center_x-32,self.center_y-32,8,8)
		spr(8,self.rhpos[1],self.rhpos[2],4,4)
		spr(8,self.lhpos[1],self.lhpos[2],4,4,1)
	 end
}

plcirc={
	center_x = 63,
	center_y = 54,
	radius = 0,
	btnmb = 0, -- beat number
	btl = 0, -- beat length

	qstbt = {}, -- question beat 
 qbang = {}, --question beat angles
 ahitwin =0.04, --answer hit window
	ansbt = {}, -- answer beat
	i=1,
	stat=0,
	lstat=0,
 plang=0, --angle of the player circle
 newr = 0, --new round switch for animation music sync
 plinput = {},
 plpos = {},
 dumtaks = 0, --number of beats that are dum or tak
 nrounds = 0,
 maxhitdisp = 10,
 hitdia = 9,

 hits = {},
 hitnum = 0,
 devi = 0, --deviation

 laststatM=0,
 mstat=0, --metronome sfx note index
 lmstat=-1, --last metronome index
 mfrm=0, --frames since metronome step
 --lhd = 0,
 --rhd = 0,
	draw=function(self)
  self.btnmb = a_bt
  self.stat=stat(50+btch)
  if(vism==1) then
			self.center_x = 63
			self.center_y = 68
			self.radius = 46
  end
		if(vism==2) then
			self.center_x = 63
			self.center_y = 54
			self.radius = 38
		end
	   	self.btnmb = a_bt
		
	  	local note
	
		--animate rotation of the circle in steps
		for i=1, self.btl do
    if(lvld.syl==1)note=self.qstbt[i]
    if(lvld.syl==0)note=self.ansbt[i]
    local angle = (i-1)/self.btl
				local x = self.center_x + self.radius * sin(angle+0.5)
    local y = self.center_y + self.radius * cos(angle+0.5)
    local xi = self.center_x + (self.radius-10) * sin(angle+0.5)
    local yi = self.center_y + (self.radius-10) * cos(angle+0.5)
				if(note==0)color=clrs.syl[1]
				if(note==1)color=clrs.syl[2]
				if(note==2)color=clrs.syl[3]
				if(bidx+1==i and lvld.eidxc==1) then
					--circ(x,y,8,clrs.epos)
				end
    if(self.stat+1==i and lvld.idxc==1) then
     --circ(x,y,9,clrs.btpos)
    elseif(self.stat+1==1 and lvld.idxc==0 and i==1) then
     circ(x,y,9,clrs.btpos)
    end
    if note==0 then
     x-=3
     y-=2
    end
    if note==1 then
     x -= 5
     y -= 2
    end
    if note==2 then
     x -= 5
     y -= 2
    end
    print(syl[note+1], x, y,color)
    print(i, xi - 1, yi - 2, clrs.posn)
		end
  --animate rotation continuously
  if 1==1 then
   --derive the angle from the
   --metronome sfx position instead
   --of free-running with bpm. the
   --old code only snapped back to 0
   --after seeing step 2, so short or
   --restarted loops could drift away
   --from the audio tracker.
   self.mstat=stat(50+metroch)
   if self.mstat!=self.lmstat then
    if self.mstat==0 and self.lmstat>=0 then
     self.nrounds += 1
    end
    self.mfrm=0
    self.lmstat=self.mstat
   else
    self.mfrm+=1
   end
   local frmperstep=max(1,spd/2)
   local phase=self.mstat+self.mfrm/frmperstep
   if phase>=self.btl then phase=self.btl-0.001 end
   self.plang=phase/self.btl

   self.plpos = {self.center_x + self.radius * sin(self.plang+0.5),
   self.center_y + self.radius * cos(self.plang+0.5)}
   circ(self.plpos[1],self.plpos[2],self.hitdia,clrs.epos)
   --print(self.lhd)
   --print(self.plang, 40)
   local firstcoord = self.plinput[1]
   --print(self.firstcoord.x, 0,10,3)
   self.hits = {}
   self.hitnum = 0
   for i=1,#self.plinput do
    --if i<#self.plinput then 
    if i>#self.plinput-self.maxhitdisp then
     local clr=clrs.syl[self.plinput[i][2]+1]
     local posx = self.center_x + self.radius * sin(self.plinput[i][1]+0.5)
     local posy = self.center_x + self.radius * cos(self.plinput[i][1]+0.5)
     circ(posx,posy+3,self.hitdia,clr)
     for b=1,self.btl do
      local input=self.plinput[i][1]
      if input>1-self.ahitwin then input = input - 1 end
      if input<self.qbang[b]+self.ahitwin and
      input>self.qbang[b]-self.ahitwin and
      beats[btord[a_bt]][b] == self.plinput[i][2] then 
       self.hitnum+=1
       self.hits[b]=flr((input-self.qbang[b])*250)
       print(self.hits[b],posx,posy+13,clr)
       --print(beats[btord[a_bt]][b],posx,posy,8)
       --print(self.hits,50,10,8)
      end
     end
     self.devi=0
     for h=1,self.btl do
      if self.hits[h]!=nil then
       self.devi+=abs(self.hits[h])
       --print(self.hits[h],posx,posy,8)
      end
     end
     self.devi= self.devi/self.hitnum
    end
   end
   print("timing:",85,2,14)
   print(self.devi,115,2,14)
   print("hits:",85,10,15)
   print(self.hitnum,106,10,15)
   print("/",112,10,15)
   print(self.dumtaks,118,10,15)
   print(self.nrounds,64,2,15)
  end
  self:hands()

 end,
   
 rhd = 0,
 lhd = 0,
 rhpos = {-1},	
 lhpos = {},
 hands=function(self)	 
  local nt = 0
  local spdhit = 2
  local spdbck = 5
  local rhst = {self.center_x-5,self.center_y-5}
  local lhst = {self.center_x-32,self.center_y+5}
  local rhmov = {-5,-5}
  local lhmov = {4,-4}
  if(lvld.hnd == 0)nt = self.ansbt[self.stat+1]
  if(lvld.hnd == 1)nt = self.qstbt[self.stat+1]
  if(self.rhpos[1] == -1) then 
  self.rhpos[1]=rhst[1]
  self.rhpos[2]=rhst[2]
  self.lhpos[1]=lhst[1]
  self.lhpos[2]=lhst[2]
  end

  if self.rhpos[1]==rhst[1] and self.rhd==-1 then self.rhd = 0 end
  if self.lhpos[1]==lhst[1] and self.lhd==-1 then self.lhd = 0 end
  
  if gst==4 then
   if self.lstat!=self.stat then
    if (nt == 1) self.rhd = 1
    if (nt == 2) self.lhd = 1
    self.lstat=self.stat
   end
  end

  if(self.rhpos[1]<=rhst[1]+rhmov[1])self.rhd = -1
  if(self.lhpos[1]>=lhst[1]+lhmov[1])self.lhd = -1

  if self.rhd==1 then 
   self.rhpos[1]+=rhmov[1]
   self.rhpos[2]+=rhmov[2]
  elseif(self.rhd==-1) then 
   self.rhpos[1] += 1
   self.rhpos[2] += 1
  end
  if self.lhd==1 then 
   self.lhpos[1]+=lhmov[1]
   self.lhpos[2]+=lhmov[2]
  elseif(self.lhd== -1) then 
   self.lhpos[1] -= 1
   self.lhpos[2] += 1
  end
  spr(0,self.center_x-32,self.center_y-32,8,8)
  spr(8,self.rhpos[1],self.rhpos[2],4,4)
  spr(8,self.lhpos[1],self.lhpos[2],4,4,1)
	end
}


bscore={
	x=2, --x-pos
	y=114, --x-pos
	w=123, --width
	th=0, --thickness
	nr=2, --note radius
	noff=4,
	nl=9,
	nfl=5,
	nfw=3,
	btnmb=0,
	btl=0,
	d_line=function(self)
		rectfill(self.x,self.y,self.x+self.w,self.y-self.th,6)
	end,
 	draw=function(self)
		self.btnmb = a_bt
		self.btl = train.abtl
		x=self.x
		y=self.y
		w=self.w
		nr=self.nr
		noff=self.noff
		nl=self.nl
		nfl=self.nfl
		nfw=self.nfw
		r8l=6
		r8w=4
		self:d_line()
		for i=1, self.btl do
			local pos = (i-1)/self.btl*self.w
			local note
			if(lvld.nts==1)note=hear.qstbt[i]
			if(lvld.nts==0)note=hear.ansbt[i]
			if(note==0)then
				line(x+noff+pos+r8w/2,y-r8l/2,x+noff+pos-r8w/2+1,y+r8l/2,clrs.syl[1])
				line(x+noff+pos+r8w/2,y-r8l/2,x+noff+pos-r8w/2,y-r8l/2+1,clrs.syl[1])
			end
			if(note==1)then
				circfill(x+noff+pos,y,nr,clrs.syl[2])
				line(x+noff+pos-nr,y,x+noff+pos-nr,y+nl,clrs.syl[2])
				line(x+noff+pos-nr,y+nl,x+noff+pos-nr+nfw,y+nl-nfl,clrs.syl[2])
			end
			if(note==2)then
				circfill(x+noff+pos,y,nr,clrs.syl[3])
				line(x+noff+pos+nr,y,x+noff+pos+nr,y-nl,clrs.syl[3])
				line(x+noff+pos+nr,y-nl,x+noff+pos+nr+nfw,y-nl+nfl,clrs.syl[3])
			end
			if(bidx+1==i and lvld.eidxs==1)rect(x+noff+pos-nr-2,y+nl+2,x+noff+pos+nr+4,y-nl-2,clrs.epos)
			if(stat(50+btch)+1==i and lvld.idxs==1) then
				rect(x+noff+pos-nr-2,y+nl+2,x+noff+pos+nr+4,y-nl-2,clrs.btpos)
			elseif(stat(50+btch)+1==1 and lvld.idxs==0 and i==1) then
				rect(x+noff+pos-nr-2,y+nl+2,x+noff+pos+nr+4,y-nl-2,clrs.btpos)
			end
		end
	end
}



function mk_beat(idx)
	set_loop(btsfx,0,#beats[btord[idx]])
	for x=1,#beats[btord[idx]] do
		if beats[btord[idx]][x]==1 then
			set_note(btsfx,x-1,make_note(19,dumsfx+8,7,0))
		elseif beats[btord[idx]][x]==2 then
  			set_note(btsfx,x-1,make_note(18,taksfx+8,7,0))
  		elseif beats[btord[idx]][x]==0 then
  			set_note(btsfx,x-1,make_note(15,essfx+8,1,0))
		end
	end
	sfx(btsfx)
end

function spd2bpm(speed)
 bpm = 60 / (speed / (120 / 2))   
 return bpm
end

function make_note(pitch, instr, vol, effect)
 return { pitch + ((instr%4)<<6) , (instr\8<<7) + (effect<<4) + (vol<<1) + (instr%8)\4 }
 --{ iipppppp, ceeevvvi }
end

function get_note(sfx, time)
 local addr = 0x3200 + 68*sfx + 2*time
 return { peek(addr) , peek(addr + 1) }
end

function set_note(sfx, time, note)
 local addr = 0x3200 + 68*sfx + 2*time
 poke(addr, note[1])
 poke(addr+1, note[2])
end

function get_spd(sfx)
 return peek(0x3200 + 68*sfx + 65)
end

function set_spd(sfx, speed)
 poke(0x3200 + 68*sfx + 65, speed)
end

function set_loop(sfx, start, en)
 local addr = 0x3200 + 68*sfx
 poke(addr + 66, start)
 poke(addr + 67, en)
end

function rrectfill(x0, y0, x1, y1, col, edgeR)

	local tl = edgeR
	local tr = edgeR 
	local bl = edgeR
	local br = edgeR

	--local tl = corners and corners.tl
	--local tr = corners and corners.tr
	--local bl = corners and corners.bl
	--local br = corners and corners.br
  
	local new_x0 = x0 + max(tl, bl)
	local new_y0 = y0 + max(tl, tr)
	local new_x1 = x1 - max(tr, br)
	local new_y1 = y1 - max(bl, br)
  
	rectfill(new_x0, new_y0, new_x1, new_y1, col)
  
	if tl and tl>0 then
	  circfill(new_x0, new_y0, tl, col)
	end
	if tr and tr>0 then
	  circfill(new_x1, new_y0, tr, col)
	end
	if bl and bl>0 then
	  circfill(new_x0, new_y1, bl, col)
	end
	if br and br>0 then
	  circfill(new_x1, new_y1, br, col)
	end
  
	-- draw top rect
	rectfill(new_x0, y0, new_x1, new_y0, col)
  
	-- draw left rect
	rectfill(x0, new_y0, new_x0, new_y1, col)
  
	-- draw right rect
	rectfill(new_x1, new_y0, x1, new_y1, col)
  
	-- draw bottom rect
	rectfill(new_x0, new_y1, new_x1, y1, col)
  end

  function trifill(x1, y1, x2, y2, x3, y3, col)
    -- Hilfsfunktion, um die x-Position an einer gegebenen y-Position zwischen zwei Punkten zu berechnen
    local function edge_func(x0, y0, x1, y1, y)
        if y0 == y1 then return x0 end
        return x0 + (x1 - x0) * (y - y0) / (y1 - y0)
    end

    -- Sortiert die y-Werte (und zugehれへrigen x-Werte)
    if y2 < y1 then
        x1, x2 = x2, x1
        y1, y2 = y2, y1
    end
    if y3 < y1 then
        x1, x3 = x3, x1
        y1, y3 = y3, y1
    end
    if y3 < y2 then
        x2, x3 = x3, x2
        y2, y3 = y3, y2
    end

    -- Fれもllt das Dreieck zeilenweise
    for y = y1, y3 do
        if y < y2 then
            xl = edge_func(x1, y1, x2, y2, y)
            xr = edge_func(x1, y1, x3, y3, y)
        else
            xl = edge_func(x2, y2, x3, y3, y)
            xr = edge_func(x1, y1, x3, y3, y)
        end

        -- Zeichnet die Linie fれもr die aktuelle Zeile
        line(xl, y, xr, y, col)
    end
end


  


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000fff00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000fff0ffff0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000ff0ffff0ffff000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000fff0ffff0ffff00000000000000000000000000000000000000000
00000000000000000000000000044444444440000000000000000000000000000000000000ffff0ffff0ffff0000000000000000000000000000000000000000
000000000000000000000004444444444444444440000000000000000000000000000000ff0ffff0ffff0ffff000000000000000000000000000000000000000
000000000000000000000444444555555555544444400000000000000000000000000000fff0ffff0ffffffff000000000000000000000000000000000000000
000000000000000000044444555555555555555544444000000000000000000000000000ffff0ffff0fffffff000000000000000000000000000000000000000
000000000000000000444455555dddddddddd555554444000000000000000000000000000ffff0fffffffffff000000000000000000000000000000000000000
000000000000000004445555dddddddddddddddd5555444000000000000000000000000ff0ffff0ffffffffff000000000000000000000000000000000000000
0000000000000004444555dddddddddddddddddddd55544440000000000000000000000fff0ffffffffffffff000000000000000000000000000000000000000
000000000000004445555dddddddddddddddddddddd5555444000000000000000000000fffffffffffffffff0000000000000000000000000000000000000000
0000000000000044555dddddddddddddddddddddddddd55544000000000000000000000fffffffffffffffff0000000000000000000000000000000000000000
000000000000044555dddddddddddddddddddddddddddd55544000000000000000000000fffffffffffffff00000000000000000000000000000000000000000
00000000000044455dddddddddddddddddddddddddddddd55444000000000000000000000fffffffffffff000000000000000000000000000000000000000000
0000000000044455dddddddddddddddddddddddddddddddd55444000000000000000000000fffffffffff0000000000000000000000000000000000000000000
0000000000044555dddddddddddddddddddddddddddddddd555440000000000000000000000fffffffff00000000000000000000000000000000000000000000
000000000044455dddddddddddddddddddddddddddddddddd5544400000000000000000000000ffffff000000000000000000000000000000000000000000000
00000000004455dddddddddddddddddddddddddddddddddddd554400000000000000000000000000000000000000000000000000000000000000000000000000
00000000044455dddddddddddddddddddddddddddddddddddd554440000000000000000000000000000000000000000000000000000000000000000000000000
0000000004455dddddddddddddddddddddddddddddddddddddd55440000000000000000000000000000000000000000000000000000000000000000000000000
0000000004455dddddddddddddddddddddddddddddddddddddd55440000000000000000000000000000000000000000000000000000000000000000000000000
0000000004455dddddddddddddddddddddddddddddddddddddd55440000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
000000004455dddddddddddddddddddddddddddddddddddddddd5544000000000000000000000000000000000000000000000000000000000000000000000000
0000000004455dddddddddddddddddddddddddddddddddddddd55440000000000000000000000000000000000000000000000000000000000000000000000000
0000000004455dddddddddddddddddddddddddddddddddddddd55440000000000000000000000000000000000000000000000000000000000000000000000000
0000000004455dddddddddddddddddddddddddddddddddddddd55440000000000000000000000000000000000000000000000000000000000000000000000000
00000000044455dddddddddddddddddddddddddddddddddddd554440000000000000000000000000000000000000000000000000000000000000000000000000
00000000004455dddddddddddddddddddddddddddddddddddd554400000000000000000000000000000000000000000000000000000000000000000000000000
000000000044455dddddddddddddddddddddddddddddddddd5544400000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044555dddddddddddddddddddddddddddddddd55544000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044455dddddddddddddddddddddddddddddddd55444000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000044455dddddddddddddddddddddddddddddd554440000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000044555dddddddddddddddddddddddddddd5554400000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000044555dddddddddddddddddddddddddd55544000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000004445555dddddddddddddddddddddd5555444000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000004444555dddddddddddddddddddd55544440000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000004445555dddddddddddddddd5555444000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000444455555dddddddddd5555544440000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000004444455555555555555554444400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000044444455555555554444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000044444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000099999990000000000000000000000000000000000000000000000000000000000000000000000000099900000000000009000000000000000000000000
00000000000099990000000000000000000000000000000000000000000000000090000000000000000009990000000000000009000000000000000000000000
00000009000000099000000000000000000000000000000000000000000000000099999999999000000999000000000000000009000000000000000000000000
00000009000000009900000000000000000000000000000000000000000000000000000000009999999900000000000000000009000000000000000000000000
00000009900000000990000000000000000000000000000000000000000000000000000000000099000000000000000000000009900000000000000000000000
00000000900000000099000000000000000000000000000000000000000000000000000000000090000000000000000000000000900000000000000000000000
00000000990000000009900000000000000000000000000000000000000000000000000000000090000000000000000000000000900000000000000000000000
00000000090000000000990000000000000000000000000000000000000000000000000000000090000000000000000000000000900000000000000000000000
00000000090000000000099000099000000000009000999009990000999900000000000000000090000000000000000000000009900000000000000000000000
00000000090000000000009000090000000000009009909999099000900990000000000000000090000000000000000000000009999000000000000000000000
00000000090000000000009000099000000000009000000900009900990090000000000000000090000000000999900000000009909990000000000000000000
00000000090000000000009000009000000000009000000990000909900099000000000000000090000000009900090000000009000099000000000000000000
00000000090000000000009000009000000000009000000090000999000009000000000000000090000000999000090000000009000009000000000000000000
00000000090000000000009000009000000000099000000090000990000009000000000000000090000000900000090000000009000009000000000000000000
00000000090000000000009000009000000000090000000090000090000099000000000000000090000009900000099000000009000009000000000000000000
00000000090000000000009000009000000000090000000090000000000090000000000000000090000099000000099000000009000099000000000000000000
00000000090000000000009000009000000000090000000090000000000090000000000000000009000090000000009000000009000990000000000000000000
00000000090000000000009000009900000000090000000090000000000090000000000000000009000990000000009000000009000900000000000000000000
00000000090000000000009000000900000000090000000090000000000090000000000000000009000900000000009000000009000900000000000000000000
00000000090000000000099000000900000000090000000090000000000090000000000000000009000900000000009000000009000090000000000000000000
00000000090000000000090000000900000000090000000090000000000090000000000000000009000090000000099000000009000099000000000000000000
00000000090000000000090000000900000000990000000990000000000099000000000000000009000099000000999000000009000009900000000000000000
00000000990000000000990000000990000009900000000900000000000009000000000000000009000009900000909900000009900000900000000000000000
00000000900000000009900000000099900999000000000900000000000009000000000000000009000000999999900999000000000000000000000000000000
00000000900000000099000000000000999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099999990000000000000000000000000000000000000999900000000000000000000000000000000000000000000000000000000000000000000000
00000009999900009000000000000000000000000000000000099900990000000000000000000000000000000000000000000000000000000000000000000000
00000009000000009000000000000000000000000000000009990000090000000000000000000000000000000000000000000000000000000000000000000000
00000009900000000900000000000000000000000000000009000000099000000000000000000000000000000000000000000000000000000000000000000000
00000000990000000900000000000000000000000000000099000000009000000000000000000000000000000000000000000000000000000000000000000000
00000000099000000900000000000000000000000000000099000000009000000000000000000000000000000000000000000000000000000000000000000000
00000000009900000900000000000000000000000000000009900000099000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000999000090000000000000000000000000000000000000000000000000000000000000000000000
00000000000000900000000000000000000000000000000000009000090000000000000000000000000000000000000000000000000000000000000000000000
00000000009000900000000000000000000000000000000000009009990000000000000000000000000000000000000000000000000000000000000000000000
00000000009000900000000000000000000000000000000000990000990000000000000000000000000000000000000000000000000000000000000000000000
00000000009000900000000000000000000000009990000009900000090000000000000000000000000000000000000000000000000000000000000000000000
00000000009000900099999000000000000000999099000009000000099000000000000000000000000000000000000000000000000000000000000000000000
00000000999000900990009999000000000000900000999999990000009000000000000000000000000000000000000000000000000000000000000000000000
00000009900000000900000009900000000000900909999090009000009900000000000000000000000000000000000000000000000000000000000000000000
00000009000000000900999000900000000000900900009990000000000900000000000000000000000000000000000000000000000000000000000000000000
00000090000999999999909000900000000000990999099999999900000900000000000000000000000000000000000000000000000000000000000000000000
00000090000000000900009009900000000000099990009990000000000900000000000000000000000000000000000000000000000000000000000000000000
00000990000999900990009009000000000000000900999090000000000900000000000000000000000000000000000000000000000000000000000000000000
00000900000000999999999999000000000000009900900000000000009900000000000000000000000000000000000000000000000000000000000000000000
00000900000000000009999990000000000000009000900000000000009000000000000000000000000000000000000000000000000000000000000000000000
00000900000000000009000090000000000000009000900000000000000990000000000000000000000000000000000000000000000000000000000000000000
00000900000000000009000099000000000000009000900000000000000900000000000000000000000000000000000000000000000000000000000000000000
00000900000000000009000009000000000000009000900000000000000900000000000000000000000000000000000000000000000000000000000000000000
00000900000000000009000009000000000000009000990000000000000900000000000000000000000000000000000000000000000000000000000000000000
00000900000000000090000009000000000000009000090000000000000900000000000000000000000000000000000000000000000000000000000000000000
00000900000000000090000009000000000000009000090000000000000900000000000000000000000000000000000000000000000000000000000000000000
00000990000000000090000009000000000000000000090000000000000900000000000000000000000000000000000000000000000000000000000000000000
00000090000000000000000009000000000000000000090000000000000900000000000000000000000000000000000000000000000000000000000000000000
00000090000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111999199911991999191919911999111111111111111111111111111111111111111111111111111111111111111111111111111113331111188811111111
11111999191919111999191919191191111111111111111111111111111111111111111111111111111111111111111111111111111113131111181811111111
11111919199919991919191919191191111111111111111111111111111111111111111111111111111111111111111111111111111113131111181811111111
11111919191911191919191919191191111111111111111111111111111118888811111111111111111111111111111111111111111113131111181811111111
11111919191919911919119919991999111111111111111111111111111881111188111111111111111111111111111111111111111113331111188811111111
11111111111111111111111111111111111111111111111111111111118111111111811111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111181111111111181111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111811111111111118111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111811111111111118111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111118111155511551111811111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111118111151115111111811111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111118111155115551111811111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111118111151111151111811111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111118111155515511111811111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111811111111111118111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111811111111111118111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111181111111111181111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111118111111111811111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111881111188111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111118888811111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111441111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111155511551111111111111111111111111111111141111111111111111111111111111111555115511111111111111111111111111
11111111111111111111111151115111111111111111111111111111111111141111111111111111111111111111111511151111111111111111111111111111
11111111111111111111111155115551111111111111111111111111111111141111111111111111111111111111111551155511111111111111111111111111
11111111111111111111111151111151111111111111111111111111111111444111111111111111111111111111111511111511111111111111111111111111
11111111111111111111111155515511111111111111111111111111111111111111111111111111111111111111111555155111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111444111111111111111111111111111111111111111111111111114441111111111111111111111111111111111111
11111111111111111111111111111111111414111111111111111111111111111111111111111111111111111141111111111111111111111111111111111111
11111111111111111111111111111111111444111111111111111111111111111111111111111111111111114441111111111111111111111111111111111111
11111111111111111111111111111111111414111111111111111111111111111111111111111111111111114111111111111111111111111111111111111111
11111111111111111111111111111111111444111111111111111111111111111111111111111111111111114441111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111114444444444111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111144444444444444444411111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111114444445555555555444444111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111444445555555555555555444441111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111444455555dddddddddd555554444111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111114445555dddddddddddddddd555544411111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111114444555dddddddddddddddddddd5554444111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111114445555dddddddddddddddddddddd555544411111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111144555dddddddddddddddddddddddddd5554411111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111144555dddddddddddddddddddddddddddd555441111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111144455dddddddddddddddddddddddddddddd55444111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111144455dddddddddddddddddddddddddddddddd5544411111111111111111111111111111111111111111111
11111111111111111111111111111111111111111144555dddddddddddddddddddddddddddddddd5554411111111111111111111111111111111111111111111
1111111111111111111111111111111111111111144455dddddddddddddddddddddddddddddddddd554441111111111111111111111111111111111111111111
111111111111111111111111111111111111111114455dddddddddddddddddddddddddddddddddddd55441111111111111111111111111111111111111111111
111111111111111111111111111111111111111144455dddddddddddddddddddddddddddddddddddd55444111111111111111111111111111111111111111111
11111111111111111111111111111111111111114455dddddddddddddddddddddddddddddddddddddd5544111111111111111111111111111111111111111111
11111111111111111111111111111111111111114455dddddddddddddddddddddddddddddddddddddd5544111111111111111111111111111111111111111111
11111111111111111111111111111111111111114455dddddddddddddddddddddddddddddddddddddd5544111111111111111111111111111111111111111111
1111111111111111111111111111111111111114455dddddddddddddddddddddddddddddddddddddddd554411111111111111111111111111111111111111111
1111111111111111111111111111111111111114455dddddddddddddddddddddddddddddddddddddddd554411111111111111111111111111111111111111111
1111111111111111111111111111111111111114455dddddddddddddddddddddddddddddddddddddddd554411111111111111111111111111111111111111111
1111111111555115511111111444111111111114455dddddddddddddddddddddddddddddddddddddddd554411111111111144411111111555115511111111111
1111111111511151111111111114111111111114455ddddddddddddddddddddddddddddddddfffddddd554411111111111111411111111511151111111111111
1111111111551155511111111114111111111114455ddddddddddddddddddddddddddddfffdffffdddd554411111111111114411111111551155511111111111
1111111111511111511111111114111111111114455dddddddddddddddddddddddddffdffffdffffddd554411111111111111411111111511111511111111111
1111111111555155111111111114111111111114455dddddddddddddddddddddddddfffdffffdffffdd554411111111111144411111111555155111111111111
1111111111111111111111111111111111111114455dddddddddddddddddddddddddffffdffffdffffd554411111111111111111111111111111111111111111
1111111111111111111111111111111111111114455dddddddddddddddddddddddffdffffdffffdffff554411111111111111111111111111111111111111111
1111111111111111111111111111111111111114455dddddddddddddddddddddddfffdffffdffffffff554411111111111111111111111111111111111111111
11111111111111111111111111111111111111114455ddddddddddddddddddddddffffdffffdfffffff544111111111111111111111111111111111111111111
11111111111111111111111111111111111111114455dddddddddddddddddddddddffffdfffffffffff544111111111111111111111111111111111111111111
11111111111111111111111111111111111111114455dddddddddddddddddddddffdffffdffffffffff544111111111111111111111111111111111111111111
1111111111111111111111111111111111111111444fffdddddddddddddddddddfffdffffffffffffff444111111111111111111111111111111111111111111
111111111111111111111111111111111111111114ffffdfffdddddddddddddddfffffffffffffffff5441111111111111111111111111111111111111111111
11111111111111111111111111111111111111111ffff5ffffdffddddddddddddfffffffffffffffff4441111111111111111111111111111111111111111111
1111111111111111111111111111111111111111ffff5ffffdfffdddddddddddddfffffffffffffff54411111111111111111111111111111111111111111111
111111111111111111111111111111111111111ffff4ffffdffffddddddddddddddfffffffffffff544411111111111111111111111111111111111111111111
11111111111111111111111111111111111111ffff1ffff5ffffdffdddddddddddddfffffffffff5444111111111111111111111111111111111111111111111
11111111111111111111111111111111111111ffffffff5ffffdfffddddddddddddddfffffffff55441111111111111111111111111111111111111111111111
11111111111111111111111111111111111111fffffff4ffffdffffddddddddddddddddffffff554411111111111111111111111111111111111111111111111
11111111111111111111111111111111111111fffffffffff5ffffdddddddddddddddddddd555544411111111111111111111111111111111111111111111111
11111111111111111111111111111111111111ffffffffff4ffffdffddddddddddddddddd5554444111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111ffffffffffffff5fffddddddddddddddd555544411111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111fffffffffffffffff55dddddddddd555554444111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111fffffffffffffffff555555555555555444441111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111fffffffffffffff4445555555555444444111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111fffffffffffff44444444444444444411111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111114111111fffffffffff111114444444444111111111111111111114141111111111111111111111111111111111111
1111111111111111111111111111111111141111111fffffffff1111111111111111111111111111111111114141111111111111111111111111111111111111
11111111111111111111111111111111111444111111ffffff111111111111111111111111111111111111114441111111111111111111111111111111111111
11111111111111111111111111111111111414111111111111111111111111111111111111111111111111111141111111111111111111111111111111111111
11111111111111111111111111111111111444111111111111111111111111111111111111111111111111111141111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111155511551111111111111111111111111111111111111111111111111111111111111111555115511111111111111111111111111
11111111111111111111111151115111111111111111111111111111111111111111111111111111111111111111111511151111111111111111111111111111
11111111111111111111111155115551111111111111111111111111111111444111111111111111111111111111111551155511111111111111111111111111
11111111111111111111111151111151111111111111111111111111111111411111111111111111111111111111111511111511111111111111111111111111
11111111111111111111111155515511111111111111111111111111111111444111111111111111111111111111111555155111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111114111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111444111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111155511551111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111151115111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111155115551111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111151111151111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111155515511111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111333133313331111133313331111111111111111111111111111111111111111111111111111111111111111111111111111111113331113133311111111
11111313131313331131131313131111111111111111111111111111111111111111111111111111111111111111111111111111111111131131131311111111
11111331133313131111133313131111111111111111111111111111111111111111111111111111111111111111111111111111111111131131133311111111
11111313131113131131131313131111111111111111111111111111111111111111111111111111111111111111111111111111111111131131131311111111
11111333131113131111133313331111111111111111111111111111111111111111111111111111111111111111111111111111111111131311133311111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
00010000000000c6100c6300c6200c6100c60012600136001460015600166001760018600196001a6001b6001c6001d6001e6001f600206002160022600236002460025600266002760028600296002a6002b600
110100001f050180501505012050100500d0500905007050050500305002050000500105002050020500305003050030500305002050020500205001050010500005000050000500005000050000400002001000
7f010000280502005016050100500f0500f05010050110501405016050180401a0301d02016000160001600016000150001500015000160001600000000000000000000000000000000000000000000000000000
00010000270501e0401903014020100100b01004010000000c000240000c0001f0000c000280000c000000000c000000000c000000000c000000000c000000000c000000000c000000000c000000000c00000005
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600002700027000270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb45000000cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb450cb45
412008000050000500005000050000500005001053011530005000050000500005000050000500005000050000500005000050000500005000050000500005000050010500115000050000500005000050000500
892020001353013530135321353213532135321053011530135301353013532135321353213532105301153013530145301353011530135301453013530115301053210532105321053210532105321453013530
89202000115301153011530115321153211532105301153013530145301353011532105320d5320c5300c53013530115301153010532105320d5320d5320c5300c5300c5300c5300c5000c5000c5001053011530
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000080705507000020550700007055070000205507000070000700007000070000700007000070000700007000070000700007000070000700007000070000700000000000000000000000000000000000000
012000200805508000030550800008055080000305508000070550700002055070000705507000020550700007055070000205507000070550700002055070000705500000020550000007055000000205500000
__music__
01 4a420a14
01 4b420b14
02 4c420c15
02 01024344

