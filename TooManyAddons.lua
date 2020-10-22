	--[[  ----------------- from wowwiki.com -------------------   WoW 2.0
	DEFAULT_CHAT_FRAME:AddMessage("")
	DisableAddOn(index or "AddOnName")   - Disable the specified AddOn for subsequent sessions.
	DisableAllAddOns()   - Disable all AddOns for subsequent sessions.
	EnableAddOn(index or "AddOnName")   - Enable the specified AddOn for subsequent sessions.
	EnableAllAddOns()   - Enable all AddOns for subsequent sessions.
	GetAddOnDependencies(index or "AddOnName")   - Get dependency list for an AddOn.
	GetAddOnInfo(index or "AddOnName")   - Get information about an AddOn.
	GetAddOnMetadata(index or "name", "variable")   - Retrieve metadata from addon's TOC file.
	GetNumAddOns()   - Get the number of user supplied AddOns.
	IsAddOnLoaded(index or "AddOnName")   - Returns true if the specified AddOn is loaded.
	IsAddOnLoadOnDemand(index or "AddOnName")   - TMA whether an AddOn is load-on-demand.
	LoadAddOn(index or "AddOnName")   - Request loading of a Load-On-Demand AddOn.
	ResetDisabledAddOns()

	name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(index or "name")
	]]

-- the structure looks like this
--
--  TMAprofiles[x] = (profilename, {addonname = BOOLEAN}

--TMAdebug = true
local theonetable = {}  --merges local and global profiles for easier handling
local TMAincombat = false;

function TMA_onload()

    TMAframe = CreateFrame("Frame",TMAframe,UIParent)
    TMAframe:SetScript("OnEvent",TMA_onevent)

    TMAframe:RegisterEvent('VARIABLES_LOADED')
	TMAframe:RegisterEvent('PLAYER_ENTER_COMBAT')
	TMAframe:RegisterEvent('PLAYER_LEAVE_COMBAT')

	-- create our slash commands
	SLASH_TMA1 = "/TMA";
	SLASH_TMA2 = "/tma";
	SLASH_TMA3 = "/TooManyAddons";
	SLASH_TMA4 = "/toomanyaddons";
	SlashCmdList["TMA"] = TMA;

	TMAcreateinterface()
	TMAcreateoptionframe()

	if(GetNumAddOns() > 100) then
		DEFAULT_CHAT_FRAME:AddMessage(GetNumAddOns().." addons found.  You have TooManyAddons! ('/TMA help' for more info)")
	else
		DEFAULT_CHAT_FRAME:AddMessage("Only "..GetNumAddOns().." addons found.  Get some more! ('/TMA help' for more info)")
	end
 	--end loading



end



--sort menu initialization
function TMAsortMenu_Initialise(self,level)
	if(TMAincombat) then
		TMAprint("Cant show dropdowns - in combat.")
	else

	   local level = level or 1
	   if (level == 1) then
		  local info = UIDropDownMenu_CreateInfo();
		  local key, value
		  for i = 1,#TMAsortmethods do
				info.text = TMAsortmethods[i].caption
				info.value = i
				info.hasArrow = false
				info.notCheckable = false
				info.owner = self:GetParent()
				info.func =  TMAsortMenuItem_OnClick
				if(i == TMAsortmethodnum) then
					info.checked = true
				else
					info.checked = false
				end
				UIDropDownMenu_AddButton(info,level)
		  end
		end
	end
end

function TMAsortMenuItem_OnClick(self)
   --if they clicked it again, change desc/asc
   if(TMAsortmethodnum == self.value) then
        TMAsortdesc = not TMAsortdesc  --descending
        TMAprint("SWapping.  TMAsortDesc is now: "..tostring(TMAsortdesc))
   else
        TMAsortmethodnum = self.value
   end
   TMAupdate()
end





function TMAimportmenu_Initialise(self,level)
	if(TMAincombat) then
		TMAprint("Cant show dropdowns - in combat.")
	else
	   local level = level or 1 --drop down menues can have sub menues. The value of level determines the drop down sub menu tier

	   if(level == 1) then
		  local info = UIDropDownMenu_CreateInfo();
		  local key, value
		  if(TMAsettings) then
			 for key,value in pairs(TMAsettings.servers) do
				info.text = key
				info.value = key
				info.hasArrow = true
				info.notCheckable = true
				info.owner = self:GetParent()
				UIDropDownMenu_AddButton(info,level)
			 end
		  else
			info.text = "No Data"
			info.value = nil
			info.hasArrow = false
			info.owner = self:GetParent()
			UIDropDownMenu_AddButton(info,level)
		  end
	   elseif (level == 2) then
		  local info = UIDropDownMenu_CreateInfo();
		  local key, value, server, parent
		  server=UIDROPDOWNMENU_MENU_VALUE
		  if(TMAsettings and TMAsettings.servers and TMAsettings.servers[server]) then
			 for key,value in pairs(TMAsettings.servers[server]) do
				info.text = key
				info.value = {server,key}
				info.hasArrow = false
				info.server = server
				info.func =  TMAimportmenuItem_OnClick
				UIDropDownMenu_AddButton(info,level)
			 end
		  end
		end
   end
end

function TMAimportmenuItem_OnClick(self)

   -- this is where the actual importing takes place
   local playerName = UnitName("player");
   local serverName = GetRealmName();
   local index,temptable
   local server = self.value[1]
   local name = self.value[2]

   if (not (server and name)) then
        TMAprint("Server or name not found")
        return false
   end
   for index,temptable in pairs(TMAsettings.servers[server][name]) do
       --sometimes theres a garbage table floating around for whatever reason.  these 2 lines should catch it
      if type(temptable) == "table" then
    	 if temptable["profilename"] then
    	    if  (server == serverName and name == playerName) then
    	       -- it creates an infinite loop if you keep adding yourseelf
    	    else
				local tablecopy = {}

				TMAprint("A full and |c000000ff complete copy was created")
				TMA_tcopy(tablecopy,temptable) -- this is an unfortunate and slow necessity because table.insert doesnt copy tables.
				--remove the 'last selected' data
				for i = 1,#tablecopy do
					tablecopy[i].isselected = false
					tablecopy[i].islastloaded = false
				end
				table.insert(theonetable,tablecopy)  -- because otherwise merely the reference to it is inserted, meaning changing a profile changes the original
    	    end
    	 end
      end
   end

   TMAupdate()
end




function TMAgroupby_Initialise(self,level)  --currently not used

  local level = level or 1
   if (level == 1) then
      local info = UIDropDownMenu_CreateInfo();
      local key, value
      for i = 1,#TMAgroupmethods do
            info.text = TMAgroupmethods[i].caption
    	    info.value = i
    	    info.hasArrow = false
    	    info.notCheckable = false
    	    info.owner = self:GetParent()
    	    info.func =  TMAgroupby_OnClick
    	    if(i == TMAsortmethodnum) then
    	        info.checked = true
    	    else
                info.checked = false
    	    end
    	    UIDropDownMenu_AddButton(info,level)
      end
    end

end

function TMAgroupby_OnClick(self)

	TMAgroupmethodnum = self.value
	TMAupdate()
end

------------------------ event handler --------------------------
function TMA_onevent(self,event,arg1)
    TMAprint("|c00ffbb00event triggered")
    TMAprint(event)
    TMAprint(arg1)
	if (event == 'VARIABLES_LOADED') then
	   TMAinitialize()
	elseif (event == "PLAYER_ENTER_COMBAT") then
		TMAincombat = true
		TMAprint("ENTERING COMBAT!!!!!")
	elseif (event == "PLAYER_LEAVE_COMBAT") then
		TMAincombat = false
		TMAprint("leaving combat")
	end
end
-----------------------------------------------------------------

function TMAinitialize()
	TMAprint("Intializing TMAsettings")
	-- this is where we set up and retrieve global variables, stored in TMAsettings


   local playerName = UnitName("player");
   local serverName = GetRealmName();
   -- Do nothing if player name is not available
   if (playerName == nil or playerName == UNKNOWNOBJECT or playerName == UKNOWNBEING) then
      return;
   end

	local TMAaddonframe = getglobal(TMA_ADDON_LIST_NAME.."frame")
    local TMAprofileframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")

   if not (TMAsettings) then
      TMAsettings = {}
   end

   if not TMAsettings.servers then
      TMAsettings.servers = {}
	end

    --create master list of addons storing date first seen
    if not (TMAsettings.dates) then
        TMAsettings.dates = {}
    end
    for i = 1,GetNumAddOns() do
       name,title,_, _, _, _, _ = GetAddOnInfo(i)
       if not (TMAsettings.dates[name]) then
           TMAsettings.dates[name] = date("%y%m%d")
       end
	end

	-----------global profile stuff
	if not (TMAsettings.globalprofiles) then
		TMAsettings.globalprofiles = {}
	end


   if not TMAsettings.servers[serverName] then
      TMAsettings.servers[serverName] = {}
   end
   -- if nothing existed, create it all from scratch (the defauts)
	if not TMAsettings.servers[serverName][playerName] then
		TMAsettings.servers[serverName][playerName] = {}
	end

	--TMAprofiles = TMAsettings.servers[serverName][playerName]  --this is our local copy
	local profiles = TMAsettings.servers[serverName][playerName]  --this is our local copy

	--sort methods
	if not (profiles.sortmethodnum) then
		profiles.sortmethodnum = 1
    end
	TMAsortmethodnum = profiles.sortmethodnum

	if (not TMAlastgloballoaded) then
		TMAlastgloballoaded = {}
	end

	theonetable = {}  --grrrr?:(

	--local profiles, add to theonetable
	for i = 1,#profiles do
		theonetable[i+#TMAsettings.globalprofiles] = profiles[i]
		theonetable[i+#TMAsettings.globalprofiles].isglobal = false
	end


	--global profiles, add to theonetable
	for i = 1,#TMAsettings.globalprofiles do
		theonetable[i] = TMAsettings.globalprofiles[i]
		theonetable[i].isglobal = true
		theonetable[i].islastloaded = false
		--dont use the 'lastloaded' value saved in the global table because we need it to be different per character
		for j = 1,#TMAlastgloballoaded do
			if(theonetable[i].profilename == TMAlastgloballoaded[j]) then
				theonetable[i].islastloaded = true
			end
		end
	end


	if (not theonetable[1]) then
		theonetable[1] = {}
		theonetable[1].profilename = "Default"
		theonetable[1].isselected = true
		theonetable[1].isglobal = false
		theonetable[1].islastloaded = false
		for i=1, GetNumAddOns() do
			name,title,_, enabled, _, _, _ = GetAddOnInfo(i)
			--local ourbutton = getglobal(TMA_ADDON_LIST_NAME.."button"..i)
			theonetable[1][name] = enabled  --this syntax does work
		end
	end

	--TMAprint("Printing |c004444ee TheOneTable!|r from initialization")
	--TMAprint(theonetable)


-- set the position of our frame
   if TMAprofileframe then
		if(TMAsettings.profilepoints) then
			TMAprint("TMAsettings.profilepoints found!")
			TMAprofileframe:SetPoint("topleft",UIParent,"bottomleft",TMAsettings.profilepoints.left,TMAsettings.profilepoints.top)
			TMAprofileframe:SetPoint("bottomright",UIParent,"bottomleft",TMAsettings.profilepoints.right,TMAsettings.profilepoints.bottom)
		else
			TMAprint("TMAsettings.profilepoints |c00ff0000NOT |rfound!")
			--DEFAULTS.  will be overriden if there's saved values
			TMAprofileframe:SetPoint("topleft",UIParent,"topleft",100,-100)
			TMAprofileframe:SetPoint("bottomright",UIParent,"topleft",100+TMA_FRAME_WIDTH,-(100+TMA_FRAME_HEIGHT))
		end
	else
		TMAprint("TMAprofileframe |c00ff0000NOT |rfound!")
   end

 --not sure when this should be called.  put here for now.
   TMAcreatealwaysprofile()


  	TMAsortdesc = false --sort descending
    TMAcreatesortingmethods()

	 -- setup grouping table

    TMAsetupgroups()
	--TMAcreategroupingmethods()  --beta test

	if(TMAincombat) then
		TMAprint("Cant show dropdowns - in combat.")
	else
		--set dropdown menu values
		UIDropDownMenu_Initialize(TMAimportmenu,TMAimportmenu_Initialise);
		UIDropDownMenu_Initialize(TMAsortMenu,TMAsortMenu_Initialise);
		if(TMAgroupby) then--testing sometimes turns this off
			UIDropDownMenu_Initialize(TMAgroupby,TMAgroupby_Initialise);
		end
	end

	--options
	TMAinitializeoptions()

	TMAupdate()  --this is just needed here for the game menu button X_X in case they go streaight to the game menu before opening up the TMA interface

end --end initialize



function TMAinitializeoptions()
	-------options stuff-----  real options, in a options frame and everything!
		--hide or show the game menu button (when you press esc)
	if (TMAsettings.hidegamemenubutton) then
		TMAhidegamemenubutton = TMAsettings.hidegamemenubutton
	else
		TMAhidegamemenubutton = false
	end
	TMAoption1:SetChecked(TMAhidegamemenubutton)

	if (TMAsettings.grouping) then
		TMAgrouping = TMAsettings.grouping
	else
		TMAgrouping = false
	end

	TMAgrouping = false
	TMAoption2:SetChecked(TMAgrouping)
	TMAoption2:Disable()
	TMAoption2Text:SetText("|c00666666Grouping wasn't working out")

	if (TMAsettings.hidetooltips) then
		TMAhidetooltips = TMAsettings.hidetooltips
	else
		TMAhidetooltips = false
	end
	TMAoption3:SetChecked(TMAhidetooltips)

	if(TMAsettings.altlayout) then
		TMAaltlayout = TMAsettings.altlayout
	else
		TMAaltlayout = true --default shall be true.  Thus is it so.
	end
	if (TMAoption4) then
	--TMAoption4:SetChecked(TMAaltlayout)
	end

end

function TMAsetupgroups()
	local  groupname,name,title,ourstruct,prefix
    TMAprint("|c00ffff00Creating TMA Groups.")
    TMAgroups = {}
	local tempgroup = {}

	--allow them to start with everything showing or hidden
	if TMAsettings.collapseall then
		TMAcollapseall = TMAsettings.TMAcollapseall
	else
		TMAcollapseall = true
	end

	--TMAADDONSTOMAKEAGROUP


    for i=1,GetNumAddOns() do
		--loop through everything once and count each prefix
		name,title,_, _, _, _, _ = GetAddOnInfo(i)
		prefix = string.sub(name,1,TMACHARSTOCOMP)
		if not (tempgroup[prefix]) then
			tempgroup[prefix] = 0
		end
		tempgroup[prefix] = tempgroup[prefix] + 1
	end

	for i=1,GetNumAddOns() do
		name,title,_, _, _, _, _ = GetAddOnInfo(i)
		prefix = string.sub(name,1,TMACHARSTOCOMP)
		if (tempgroup[prefix] >= TMAADDONSTOMAKEAGROUP) then  --if the prefixes are more than 1
			if (not TMAgroups[prefix])  then  --check if the group already exists
				TMAgroups[prefix] = {}
				TMAgroups[prefix].collapsed = TMAcollapseall  --the default
				TMAgroups[prefix].header = name
				TMAgroups[prefix].kids = {}
			end
			ourstruct = {}
			ourstruct.name = name
			ourstruct.addonnumber = i
			table.insert(TMAgroups[prefix].kids,ourstruct)
		end
	end

end


function TMAcreategroupingmethods()
--currently not in use
	TMAgroupmethods = {}
	local ourstruct

	ourstruct = {}
    ourstruct.caption = "A-Z"
    table.insert(TMAgroupmethods,ourstruct)

	ourstruct = {}
    ourstruct.caption = "Prefix"
    table.insert(TMAgroupmethods,ourstruct)

	ourstruct = {}
    ourstruct.caption = "Author"
    table.insert(TMAgroupmethods,ourstruct)

	ourstruct = {}
    ourstruct.caption = "Date Acquired"
    table.insert(TMAgroupmethods,ourstruct)

	ourstruct = {}
    ourstruct.caption = "Dependancies"
    table.insert(TMAgroupmethods,ourstruct)



	--TMAgroupmethods = TMAsortmethods

end

function TMAcreatesortingmethods()
    --creating sorting table methods
    TMAsortmethods = {}

    --alphabetical
    ourstruct = {}
    ourstruct.caption = "Alphabetical"
    ourstruct.func = function(a,b)
        if not (a and b) then
           return false
        end
        if(TMAisgrouped(b.name) and not TMAisheader(b.name)) then
           return false
        end
        a=TMAsanitize(a.title)
        b=TMAsanitize(b.title)
        if (TMAsortdesc) then
            return a > b
        else
            return a < b
        end
    end
    table.insert(TMAsortmethods,ourstruct)

    --author
    ourstruct = {}
    ourstruct.caption = "Author"
    ourstruct.func = function(a,b)
       if not (a and b) then
           return true
        end
       local Aauthor = GetAddOnMetadata(a.name, "Author") or ""
       local Bauthor = GetAddOnMetadata(b.name, "Author") or ""
       Aauthor = TMAsanitize(Aauthor)
       Bauthor = TMAsanitize(Bauthor)
       if (TMAsortdesc) then
           return Aauthor > Bauthor
       else
           return Aauthor < Bauthor
       end
    end
    table.insert(TMAsortmethods,ourstruct)

    --default
    ourstruct = {}
    ourstruct.caption = "Bliz Default"
    ourstruct.func = function(a,b)
        return a.addonnumber < b.addonnumber
    end
    table.insert(TMAsortmethods,ourstruct)

    --checked
    ourstruct = {}
    ourstruct.caption = "Checked"
    ourstruct.func = function(a,b)
        if not (a and b) then

            return false
        end
        local achecked,bchecked = false
        for i = 1,#theonetable do
			if(theonetable[i].isselected or (theonetable[i].profilename == TMAALWAYSPROFILE)) then  --should we include stuff checked in the 'always' profile?
				if (theonetable[i][a.name] == true) then
				   achecked = true
				end
				if (theonetable[i][b.name] == true) then
				   bchecked = true
				end
			end
        end
        if(TMAsortdesc) then
            return (not achecked and bchecked)
        else
            return (achecked and not bchecked)
        end
    end
    table.insert(TMAsortmethods,ourstruct)

    --date?
    ourstruct = {}
    ourstruct.caption = "Date Acquired"
    ourstruct.func = function(a,b)
        if (TMAsortdesc) then
           return TMAsettings.dates[a.name] < TMAsettings.dates[b.name]
        else
           return TMAsettings.dates[a.name] > TMAsettings.dates[b.name]
        end

        --i'll have to capture A date on every addon
    end
    table.insert(TMAsortmethods,ourstruct)

    --enabled
    ourstruct = {}
    ourstruct.caption = "Enabled"
    ourstruct.func = function(a,b)
		local aenabled,benabled

		local _, _, _, aenabled, _, _, _ = GetAddOnInfo(a.name)
		local _, _, _, benabled, _, _, _ = GetAddOnInfo(b.name)
		if(TMAsortdesc) then
            return tostring(aenabled) > tostring(benabled)  --dont touch the <  >    yes its right
		else
            return tostring(aenabled) < tostring(benabled)
		end
    end
    table.insert(TMAsortmethods,ourstruct)

	--memory usage
    ourstruct = {}
    ourstruct.caption = "Memory usage"
    ourstruct.func = function(a,b)
		local aenabled,benabled
		local _, _, _, aenabled, _, _, _ = GetAddOnInfo(a.name)
		local _, _, _, benabled, _, _, _ = GetAddOnInfo(b.name)
		local amem,bmem
		if(aenabled) then
			amem = GetAddOnMemoryUsage(a.addonnumber)
		else
			amem = 0
		end
		if(benabled) then
			bmem = GetAddOnMemoryUsage(b.addonnumber)
		else
			bmem = 0
		end

		if(TMAsortdesc) then
			return amem < bmem
		else
			return amem > bmem
		end


    end
    table.insert(TMAsortmethods,ourstruct)


--The comparison function must return a boolean value specifying whether the first argument should be before the second argument in the sequence.
--The default behaviour is for the < comparison to be made
--'return true' will get an infinite loop, as it will swap a with b, then compare them again, and swap b with a.  return false, ok.  true, no.
end


function TMAcreatealwaysprofile()
	--TMAprint("|cc00aaffff createalwaysprofile called")
   local thealwaysprofile
   thealwaysprofile=TMAgetprofilenum(TMAALWAYSPROFILE)


   if not (thealwaysprofile) then
		-- create the 'always' profile :)
		table.insert(theonetable,{})
		theonetable[#theonetable].isglobal = false
		theonetable[#theonetable].profilename = TMAALWAYSPROFILE
		theonetable[#theonetable]["toomanyaddons"] = true  -- case matters :(

	end

end


-- when someone clicks the button or types /tma this is called
function TMA(input)
	if(input) then
		if(input == "help") then
			local helpspam = {}
			 helpspam[1] = "*** Welcome to TooManyAddons!  Features that aren't instantly obvious:\n*There is a new 'addon' button in the game menu, that opens up the TooManyAddons interface.\n* '/TMA' will also open up the interface."
			 helpspam[2] = "\n* '/TMA someProfile' will instantly load that profile.\n  Handy for you macrophiles.  Spelling is  exact."
			 helpspam[3] = "\n* The interface can be moved by dragging the 'profile' frame.\n  You have to click on the edge of the frame or a clear spot."
			 helpspam[4] = "\n* A profile called 'Default' is created at the very first use of TooManyAddons, for your convenience.  Feel free to delete it."
			 helpspam[5] = "\n* A profile called 'Always Load These Addons' will always exist.  Anything checked in this profile will always load, no matter what.  The checked items will appear grey or shiny in other profiles.  By default, TooManyAddons will be checked in this profile."
			 helpspam[6] = "\n* Tooltips show you the description of the addon.\n* Clicking an addon will automatically click all of its dependencies."
			 helpspam[7] = "\n* Addons with the same first four letters are grouped up.\n Clicking the head of a group will act as if you clicked everything in the group."
			 helpspam[8] = "\n* Hold down the Ctrl or Shift key when selecting profiles to load addons from multiple profiles."
			 helpspam[9] = "\n* The most recently loaded profile(s) will appear green."
			 helpspam[10] = "\n* '/TMA hidebutton' will remove the 'addon' button in the game menu."

			 for i = 1,#helpspam do
				 DEFAULT_CHAT_FRAME:AddMessage(helpspam[i])
			 end

		elseif (input == "test" and TMAdebug) then
			 TMAprint("Running our Test code.")

				TMAsettings.globalprofiles = {}
				TMAupdate()



		elseif (input == "debug") then
			TMAdebug = not TMAdebug
			DEFAULT_CHAT_FRAME:AddMessage("debug: "..tostring(TMAdebug))
		elseif (input == "hidebutton") then
			TMAhidegamemenubutton = not TMAhidegamemenubutton
			DEFAULT_CHAT_FRAME:AddMessage("TMA Game Menu Button Hidden?:".."|c00ff00ff"..tostring(TMAhidegamemenubutton).."|r")
		elseif (input == "hidegrouping") then
			TMAgrouping = not TMAgrouping
			DEFAULT_CHAT_FRAME:AddMessage("Grouping on?  :".."|c00ff00ff"..tostring(TMAgrouping).."|r")
			if (TMAgrouping) then
				TMAsetupgroups()
			else
				TMAprint("Setting TMAGROUPS to |c00ff0000 Nil")
				TMAgroups = nil
			end
		elseif (input == "option" or input == "options") then
			InterfaceOptionsFrame_OpenToCategory("TooManyAddons");

		else  -- this is for macrophiles who want to go '/tma raid', thus loading a profile with no mouse clicks
			   --DEFAULT_CHAT_FRAME:AddMessage(input)
				if(input ~= "") then
					TMAloadprofile(input)
				else  --input was ""
					-- open the interface.
				   local pframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")
				   local aframe = getglobal(TMA_ADDON_LIST_NAME.."frame")
				   if(pframe and aframe) then
					  if(pframe:IsVisible())then
						pframe:Hide()
						aframe:Hide()
					  else
						pframe:Show()
						aframe:Show()
					  end
				   end
				   TMAscrollbar_update(TMA_PROFILE_LIST_NAME)
				end
			end

	else --no input  --called when you push the addon button in the game menu

		-- open the interface.
		local pframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")
		local aframe = getglobal(TMA_ADDON_LIST_NAME.."frame")
		if(pframe and aframe) then
		  if(pframe:IsVisible())then
			pframe:Hide()
			aframe:Hide()
		  else
			pframe:Show()
			aframe:Show()
		  end
		end
	   TMAscrollbar_update(TMA_PROFILE_LIST_NAME)

	end

	TMAupdate()

end





------------------------------------- UPDATE ----------------------------------
--all graphical stuff happens here.
function TMAupdate()
    TMAprint("|cc00aaffffTMA update called")

	TMAupdateaddonframe()

	TMAupdateprofileframe()

	TMAupdateglobalprofileframe()

--sort dropdown
   if(TMAsortmethodnum) then
       TMAsortmenubutton:SetText(TMAsortmethods[TMAsortmethodnum].caption)
   else
       TMAsortmenubutton:SetText("Sort By:")
   end
   if(TMAgroupbybutton) then
	   if(TMAgroupmethodnum) then
		   TMAgroupbybutton:SetText(TMAgroupmethods[TMAgroupmethodnum].caption)
	   else
		   TMAgroupbybutton:SetText("Group By:")
	   end
	end


   TMAgamemenubuttonstuff()

   TMAsavesettings()

end --end update

function TMAupdateaddonframe()

	local name,title,notes,ourstruct,currentbutton,currentcheckbutton,ourtitle,numtodisplay,collapsebutton,ourstruct,addonname,addontitle,addonnumber
    local isgrey,isalways,ischecked
	local thealwaysprofile

	--GET the objects we will be working with
	local TMAaddonframe = getglobal(TMA_ADDON_LIST_NAME.."frame")
    local TMAprofileframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")


    if not(TMAaddonframe and TMAprofileframe) then return false end;
	if (#theonetable == 0) then
		TMAaddonframe:Hide()
		return false
	end;

	if (not TMAaddonframe:IsVisible() and TMAprofileframe:IsVisible()) then
		TMAaddonframe:Show()
	end
	if not (TMAprofileframe:IsVisible()) then
		TMAaddonframe:Hide()
		return
	end


	TMAcreatedisplaylist()  -- this is where the real logic takes place.  most bugs will be here.

	local ourscrollbar = getglobal(TMA_ADDON_LIST_NAME.."scrollbarScrollBar")
	--set scroll bar limits
	local rtcf = TMArowsthatcanfit(TMA_ADDON_LIST_NAME)
	ourscrollbar:SetMinMaxValues(0,math.max(0,#TMAaddondisplaylist-rtcf))
	--get the scroll bar value
	offset = floor(ourscrollbar:GetValue())
	TMAprint("|cc00aaeeff offset"..offset.."  Rtcf:"..rtcf.."  #TMAaddondisplaylist:"..#TMAaddondisplaylist)
	TMAhideallbuttons(false,TMA_ADDON_LIST_NAME)



	local isthealwaysselected = TMAisthealwaysselected()  --is the always profile currently one of the checked profiles?
	local currentcollapsebutton,currentcheckbutton,currentbutton, value, ratio
	ratio = {-.2,1,-.1,1.1}
	--create that many buttons and check buttons
	for i=1,rtcf do
		isalways = false
		ischecked = false

		--check if the button exists already  --checkbutton first, then regular button
		currentcheckbutton = getglobal(TMA_ADDON_LIST_NAME.."checkbutton"..i)
		if not currentcheckbutton then
			TMAcreateaddonbutton(i)
		end
		currentcheckbutton = getglobal(TMA_ADDON_LIST_NAME.."checkbutton"..i)
		currentbutton = getglobal(TMA_ADDON_LIST_NAME.."button"..i)
		currentcollapsebutton = getglobal("TMAcollapsebutton"..i)

		numtodisplay = offset + i

		if(TMAaddondisplaylist[numtodisplay]) then
			addontitle = TMAaddondisplaylist[numtodisplay].title
			addonname = TMAaddondisplaylist[numtodisplay].name
			addonnumber = TMAaddondisplaylist[numtodisplay].addonnumber
		else
			return false
		end

		--set the +/- button
		if (TMAgrouping and currentcollapsebutton) then
			if(TMAisheader(addonname)) then  --grouping crap

				currentcollapsebutton:Show()
				--update +/-
				local groupname = string.sub(addonname,1,TMACHARSTOCOMP)
				currentcollapsebutton.groupname = groupname

				if (TMAgroups[groupname].collapsed) then
				   --currentcollapsebutton:SetText("+")
				   currentcollapsebutton:SetNormalTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Up")
				  currentcollapsebutton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Up")
				  currentcollapsebutton:SetPushedTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Down")
				else
				   --currentcollapsebutton:SetText("-")
				   currentcollapsebutton:SetNormalTexture("Interface\\Minimap\\UI-Minimap-ZoomOutButton-Up")
				   currentcollapsebutton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomOutButton-Up")
				   currentcollapsebutton:SetPushedTexture("Interface\\Minimap\\UI-Minimap-ZoomOutButton-Down")
				end
			else
				currentcollapsebutton.groupname = nil
				currentcollapsebutton:Hide()
			end
		end
		--strink the text on groups??  no, make it green.  No, indent it!  No, different font!
		if(TMAisgrouped(addonname) and (not TMAisheader(addonname))) then
			currentbutton:SetNormalFontObject(GameFontNormalSmall)
			--shrink the buttons
			currentcheckbutton:GetNormalTexture():SetTexCoord(ratio[1],ratio[2],ratio[3],ratio[4])
			currentcheckbutton:GetPushedTexture():SetTexCoord(ratio[1],ratio[2],ratio[3],ratio[4])
			currentcheckbutton:GetCheckedTexture():SetTexCoord(ratio[1],ratio[2],ratio[3],ratio[4])
			currentcheckbutton:GetHighlightTexture():SetTexCoord(ratio[1],ratio[2],ratio[3],ratio[4])
			currentcheckbutton:GetDisabledTexture():SetTexCoord(ratio[1],ratio[2],ratio[3],ratio[4])
		else
			currentbutton:SetNormalFontObject(GameFontNormal)
			currentcheckbutton:GetNormalTexture():SetTexCoord(0,1,0,1)
			currentcheckbutton:GetPushedTexture():SetTexCoord(0,1,0,1)
			currentcheckbutton:GetCheckedTexture():SetTexCoord(0,1,0,1)
			currentcheckbutton:GetHighlightTexture():SetTexCoord(0,1,0,1)
			currentcheckbutton:GetDisabledTexture():SetTexCoord(0,1,0,1)
		end

		--get checked value for displayed profile  and texture and set accordingly


		--for each profile selected, both global and regular
			--check each addon in each profile
		--if it is enabled in even one, then check the button and go to next checkbutton
		--if not checked in any profile, uncheck

		--textures:
		-- UP means not checked
		-- CHECK means checked
		--normal texture includes edges.. i think?


		ischecked = TMAisshowcheck(addonname)  --is it enabled for a currently checked profile?
		if(not isthealwaysselected) then  --see, if the 'always show these addons' profile is part of the current selection, then we don't show addons in the always profile as grey, or shiny; since thealwaysprofile is now a 'normal' profile for the purposes of clicking and selecting.  i think.
			isalways = TMAischeckedinalways(addonname)	--is it part of the always show profile?
		end
		if(ischecked and isalways) then
			currentcheckbutton:SetChecked(true)
			currentcheckbutton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
			currentcheckbutton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
			--currentcheckbutton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check-Up")  -- this would make all checked boxes appear invisible.
		elseif (ischecked) then
			currentcheckbutton:SetChecked(true)
			currentcheckbutton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up") --reset  to default texture
			currentcheckbutton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check") --must explicitly set, or it will BUG

		elseif (isalways) then
			currentcheckbutton:SetChecked(false)
			currentcheckbutton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
			currentcheckbutton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled") --must explicitly set, or it will BUG

		else
			currentcheckbutton:SetChecked(false)
			currentcheckbutton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up") --reset  to default texture
			currentcheckbutton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check") --must explicitly set, or it will BUG
			--currentcheckbutton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check-Up")  -- this SOMEHOW makes all non-checked boxes appear invisible.  Its kinda cool
		end

		--set stuff for when we click it and mouseover
		currentcheckbutton.name = addonname
		currentbutton.name = addonname
		currentcheckbutton.addonnumber = addonnumber
		currentbutton.addonnumber = addonnumber
		currentbutton:SetText(addontitle)
		currentbutton:Show()
		currentcheckbutton:Show()

	end --end for rowsthatcanfit

	if (TMAgrouping) then
		TMAcollapseallbutton:Show()
		--The collapse all button stuff
		if (not TMAcollapseall) then
			TMAcollapseallbutton:SetPushedTexture("Interface\\Minimap\\UI-Minimap-ZoomOutButton-Down")
			TMAcollapseallbutton:SetNormalTexture("Interface\\Minimap\\UI-Minimap-ZoomOutButton-Up")
			TMAcollapseallbutton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomOutButton-Up")
		else
			TMAcollapseallbutton:SetPushedTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Down")
			TMAcollapseallbutton:SetNormalTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Up")
			TMAcollapseallbutton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Up")
		end
	else

		TMAcollapseallbutton:Hide()
	end

	if(TMAaltlayout) then
		TMAchooseglobalbutton:Show()
	else
		TMAchooseglobalbutton:Hide()
	end

end


function TMAisshowcheck(addonname)
	--returns IsItChecked,IsItInAlways

	---sigh.. i cant think.
	--ok.  so.  If the addon is marked as enabled in ANY selected profile, we want it to be checked
	--if it is enabled in any profile AND it is enabled in either of the ALWAYS profiles, we want it to be a shiny check
	--if it is not enabled in any selected profile, but is in a Always profile, we want it to be a grey check
	--if it is in none, then no check


	for i = 1,#theonetable do
		if(theonetable[i].isselected) then --is this profile selected?
			if(theonetable[i][addonname]) then --for the selected profile, does an entry exist for this addon we are currently looking at?  (and is the entry anything but false)
				return true -- if it is selected in any checked profile, no need to search the rest of the profiles.  return true and exit
			end
		end
	end

	return false
end

function TMAischeckedinalways(addonname)

	---sigh.. i cant think.  I feel terrible, chewy..
	--ok.  so.  If the addon is marked as enabled in ANY selected profile, we want it to be checked - but what type of check?
	--if it is enabled in any profile AND it is enabled in either of the ALWAYS profiles, we want it to be a shiny check
	--unless  an Always frame  is currently showing/selected.  In that case that always frame is just a normal frame
	--if it is not enabled in any selected profile, but is in a Always thealwaysprofile, we want it to be a grey check
	--if it is in none, then no check



	for i = 1,#theonetable do
		if(theonetable[i].profilename == TMAALWAYSPROFILE) then
			if(theonetable[i][addonname]) then --in the unlikely case they create another profile with the exact same name (Always Load These Addons), then we should look at them all to see if any of them are true
				return theonetable[i][addonname]
			end
		end
	end

	return false

end

function TMAisthealwaysselected()

	for i = 1,#theonetable do
		if(theonetable[i].profilename == TMAALWAYSPROFILE and theonetable[i].isselected) then
			return true
		end
	end
	return false
end


function TMAupdateprofileframe()
	--TMAprint("|c00ffff00Entering update profile")
    ------------------=================----------------
    --now do it all again for the profile list  --!!  yey   !!
    ---------------------------------------------------

    local TMAaddonframe = getglobal(TMA_ADDON_LIST_NAME.."frame")
    local TMAprofileframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")
	local name,title,notes,ourstruct,currentbutton,currentcheckbutton,ourtitle,numtodisplay,collapsebutton,ourstruct,addonname,addontitle,addonnumber
    --local issecondary
	local profilename,profile
	local insertcolor
--GET the objects we will be working with

    if not(TMAaddonframe and TMAprofileframe) then return false end;


    local ourscrollbar = getglobal(TMA_PROFILE_LIST_NAME.."scrollbarScrollBar")
    local ourscrollbarframe = getglobal(TMA_PROFILE_LIST_NAME.."scrollbar")

	local optimalheight = (#theonetable + 2) * TMA_ROW_HEIGHT  --no idea why the 2 but its needed


	local currentheight = TMAprofileframe:GetHeight()
	if(currentheight > 700) then  --screen height
		TMAprofileframe:SetHeight(optimalheight)
	end
    if(currentheight > optimalheight) then
        ourscrollbar:Hide()
        ourscrollbarframe:Hide()
    else
        ourscrollbar:Show()
        ourscrollbarframe:Show()
    end


    --figure out how many rows can fit
    local rtcf = TMArowsthatcanfit(TMA_PROFILE_LIST_NAME)
	--TMAprint(rtcf.." rows can fit in height() of "..TMAprofileframe:GetHeight())
    --set scroll bar limits
    ourscrollbar:SetMinMaxValues(0,math.max(#theonetable-rtcf,0))
    --get the scroll bar value
	offset = ourscrollbar:GetValue()


    TMAhideallbuttons(false,TMA_PROFILE_LIST_NAME)

    --create that many buttons and check buttons
    for i=1,rtcf do
        --check if the button exists already  --checkbutton firsr, then regular button
        currentcheckbutton = getglobal(TMA_PROFILE_LIST_NAME.."checkbutton"..i)
        if not currentcheckbutton then
            TMAcreateprofilerows(i)
        end
        currentbutton = getglobal(TMA_PROFILE_LIST_NAME.."button"..i)
        currentcheckbutton = getglobal(TMA_PROFILE_LIST_NAME.."checkbutton"..i)

        --display valid item in current button
        numtodisplay = offset + i

		currentbutton:SetNormalFontObject(GameFontNormal);   --reset color
		currentbutton.tooltip = nil
		currentcheckbutton:SetChecked(false)
		insertcolor = ""

		if(theonetable[numtodisplay]) then
			profile = theonetable[numtodisplay]
		else
			return  --out of profiles to show
		end

		if (profile.isglobal) then
			if(TMAislastloaded(numtodisplay))  then
				insertcolor = "|c0088ffbb"  --bluegreenish
			else
				insertcolor = "|c008888ff"
				currentbutton.tooltip = "Blue profiles are global.  They are the same for all of your characters."
			end
		else
			if(TMAislastloaded(numtodisplay))  then 		--show last profile in green
				currentbutton:SetNormalFontObject(GameFontGreen);
				currentbutton.tooltip = "Green profiles are your most recently loaded profiles."
			end
		end


		profilename = profile.profilename
		currentcheckbutton.number = numtodisplay

		currentbutton:SetText(insertcolor..profilename)
		if (profile.isselected) then
			currentcheckbutton:SetChecked(true)
		end
		currentbutton:Show()
		currentcheckbutton:Show()

   end

	TMAlocalorglobalbuttonstuff()

end

function TMAlocalorglobalbuttonstuff()  --you know, that 'convert to whatever' button
	local button = TMAchooseglobalbutton
	local foundglobal,foundlocal = false

	for i = 1,#theonetable do
		if(theonetable[i].isselected) then
			if(theonetable[i].isglobal) then
				foundglobal = true
			else
				foundlocal = true
			end
		end

	end

	if(foundglobal and foundlocal) then
		button:Disable()
	else
		if(foundglobal) then
			button:SetText("Make Local")
			button.tooltip="Convert the selected Global profile into a local one"
		else
			button:SetText("Make Global")
			button.tooltip="Convert the selected profile into a global one"
		end
		button:Enable()
	end
end




function TMAupdateglobalprofileframe()  --not in use
--[[
    ------------------=================----------------
    --now do it all again for the GLOBAL profile list  --!!  yey   !!
    ---------------------------------------------------
	local profilename
	--local profilepointer
    local globalprofileframe = getglobal(TMA_GLOBAL_PROFILE_LIST_NAME.."frame")

    if not(globalprofileframe) then return false end;

	if(TMAaltlayout == true) then  --:)
		globalprofileframe:Hide()
		return
	else
		globalprofileframe:Show()
	end


    local ourscrollbar = getglobal(TMA_GLOBAL_PROFILE_LIST_NAME.."scrollbarScrollBar")
    local ourscrollbarframe = getglobal(TMA_GLOBAL_PROFILE_LIST_NAME.."scrollbar")
    local newheight = (#TMAsettings.globalprofiles + 2) * TMA_ROW_HEIGHT  --no idea why the 2 but its needed

    globalprofileframe:SetHeight(math.min(TMA_FRAME_HEIGHT,newheight))
    if(newheight < TMA_FRAME_HEIGHT) then
        ourscrollbar:Hide()
        ourscrollbarframe:Hide()
    else
        ourscrollbar:Show()
        ourscrollbarframe:Show()
    end


    --figure out how many rows can fit
    local rtcf = TMArowsthatcanfit(TMA_GLOBAL_PROFILE_LIST_NAME)
    --set scroll bar limits
    ourscrollbar:SetMinMaxValues(0,math.max((#TMAsettings.globalprofiles)-rtcf,0))
    --get the scroll bar value
	offset = ourscrollbar:GetValue()

    TMAhideallbuttons(true) --this is when we redraw the size of the frames

    --create that many buttons and check buttons
    for i=1,rtcf do

        --check if the button exists already  --checkbutton firsr, then regular button
        currentcheckbutton = getglobal(TMA_GLOBAL_PROFILE_LIST_NAME.."checkbutton"..i)
        if not currentcheckbutton then
            TMAcreateglobalprofilerows(i)
			currentcheckbutton = getglobal(TMA_GLOBAL_PROFILE_LIST_NAME.."checkbutton"..i)
        end
        currentbutton = getglobal(TMA_GLOBAL_PROFILE_LIST_NAME.."button"..i)



        --display valid item in current button
        numtodisplay = offset + i
        --set text

        if(TMAsettings.globalprofiles[numtodisplay] and TMAsettings.globalprofiles[numtodisplay].profilename) then
			profilename = TMAsettings.globalprofiles[numtodisplay].profilename
			--currentcheckbutton.number = numtodisplay
			currentcheckbutton.number = numtodisplay+#TMAprofiles  --so global profiles will always have a number higher than the number given to local profiles.   lets see how it goes.

            currentbutton:SetText(profilename)
            currentbutton:Show()
            currentcheckbutton:Show()
        else
           currentcheckbutton:Hide()
           currentbutton:Hide()
        end

		--show last loaded as green
		if(TMAislastloaded(numtodisplay))  then --true for global
			currentbutton:SetNormalFontObject(GameFontNormal);
			tmafont = currentbutton:GetNormalFontObject();
			tmafont:SetTextColor(.1, 1, 0.3, 1.0); --green?
			currentbutton:SetNormalFontObject(tmafont);
		else
			currentbutton:SetNormalFontObject(GameFontNormal);
		end

		currentcheckbutton:SetChecked(false)
   end
   ]]
end



function TMAgamemenubuttonstuff()
	if (TMAhidegamemenubutton == true) then
		TMAgamemenubutton:Hide()
		-- resize the blizzard menu
		GameMenuFrame:SetHeight(TMAoriggamemenuheight);
		GameMenuButtonLogout:SetPoint("TOP", GameMenuButtonMacros, "BOTTOM", 0, -1);


	else
		TMAgamemenubutton:Show()
		-- resize the blizzard menu
		GameMenuFrame:SetHeight(TMAoriggamemenuheight + TMAgamemenubutton:GetHeight());
		GameMenuButtonLogout:SetPoint("TOP", GameMenuButtonTMAAddOns, "BOTTOM", 0, -1);
	end

end

function TMAcreatedisplaylist()  --main display logic here
--create addon display list
	local tempaddondisplaylist
	tempaddondisplaylist = {}
    TMAaddondisplaylist = {}

	--if we dont want any grouping to show
	if not (TMAgrouping) and (TMAgroups) then
		TMAgroups = nil
	end

	--if we do want grouping enabled
	if(TMAgrouping) and (not TMAgroups) then
		TMAsetupgroups()  --recreate out TMAgroups table
	end


    --just add non-groups.  groups will come after the sorting.
    for i=1,GetNumAddOns() do
        name,title,notes, _, _, _, _ = GetAddOnInfo(i)
        if ((not TMAisgrouped(name)) or TMAisheader(name)) then
           --add it to our 'display' list
           ourstruct = {}
           ourstruct.name = name
           ourstruct.title = title
           ourstruct.notes = notes
           ourstruct.addonnumber = i
           table.insert(tempaddondisplaylist,ourstruct)
        end
    end

    if(TMAsortmethodnum) then
        local TMAsortfunc = TMAsortmethods[TMAsortmethodnum].func
        table.sort(tempaddondisplaylist,TMAsortfunc)
    end

    --add kids

	local prefix,addonname ,addonnumber
	for j = 1,#tempaddondisplaylist do

		table.insert(TMAaddondisplaylist,tempaddondisplaylist[j])

		if (TMAisheader(tempaddondisplaylist[j].name)) then
			prefix = string.sub(TMAisheader(tempaddondisplaylist[j].name),1,TMACHARSTOCOMP)
			if not (TMAgroups[prefix].collapsed) then
				for i = 2, #TMAgroups[prefix].kids do  --this stuff was set up when we created TMAgroups
				   addonnumber = TMAgroups[prefix].kids[i].addonnumber
				   local name,title,notes, _, _, _, _ = GetAddOnInfo(addonnumber)
				   ourstruct = {}
				   ourstruct.name = name
				   ourstruct.title = title
				   ourstruct.notes = notes
				   ourstruct.addonnumber = addonnumber
				   table.insert(TMAaddondisplaylist,ourstruct)
				end
			end

		else
			--debugging


		end
	end


end




-------------------{}{}{}{}{}{}[][][][][][]{}{}{}{}{}--------------------------
function TMAhideallbuttons(global,name)

	if not name then name = TMA_GLOBAL_PROFILE_LIST_NAME end;
    local i = 1
    local myexit,currentcheckbutton,currentbutton
    while (not myexit) do
		if(global == true) then
			currentcheckbutton = getglobal(name.."checkbutton"..i)
			currentbutton = getglobal(name.."button"..i)
		else
			currentcheckbutton = getglobal(name.."checkbutton"..i)
			currentbutton = getglobal(name.."button"..i)
		end
        if (currentcheckbutton) then
		--	TMAprint("Hiding current button "..i)
           currentcheckbutton:Hide()
           currentbutton:Hide()
        else
            myexit = true

        end
        i=i+1
    end
end


function TMAisgrouped(name)
    if(TMAgroups and name) then
        if (TMAgroups[string.sub(name,1,TMACHARSTOCOMP)]) then
            return string.sub(name,1,TMACHARSTOCOMP)
        else
            return false
        end

    end
    return false
end

function TMAisdisabled(addonname)
	if not addonname then return false end;
    local enabled
    _,_,_,enabled = GetAddOnInfo(addonname)
    if(enabled) then
        return false
    else
        return true
    end

end

function TMAiscollapsed(name)
    if(name and TMAisgrouped(name)) then
       return TMAgroups[string.sub(name,1,TMACHARSTOCOMP)].collapsed
    end
   return false
end

function TMAisheader(name)
    local curgroup
    if not (name and TMAgroups and TMAgrouping) then return false end;
    curgroup = TMAgroups[string.sub(name,1,TMACHARSTOCOMP)]
    if(curgroup) then
      if(curgroup.header == name) then
        return string.sub(name,1,TMACHARSTOCOMP)
      end
    end
    return false
end



function TMAislastloaded(numtodisplay)
		--show last loaded as green
		return theonetable[numtodisplay].islastloaded  --this is so much easier i hate myself

end

--+_+_+_+_+_+_saving settings
function TMAsavesettings()
   ---------- -- save our TMAprofile data structure to the larger TMAsettings so it will be saved globally amongnst all players/realms

	local playerName = UnitName("player");
	local serverName = GetRealmName();
	-- Do nothing if player name is not available
	if (playerName == nil or playerName == UNKNOWNOBJECT or playerName == UKNOWNBEING) then
		return;
	end
	local i
	local TMAprofiles = {}

	local TMAaddonframe = getglobal(TMA_ADDON_LIST_NAME.."frame")
    local TMAprofileframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")


	for i = 1,#theonetable do
		if not (theonetable[i].isglobal) then
			table.insert(TMAprofiles,theonetable[i])
		end
	end
	--TMAsettings.servers[serverName][playerName] = {}  --shouldnt be necessary
    TMAsettings.servers[serverName][playerName] = TMAprofiles

	--somewhere here we have to update the GlobalProfile table
	TMAsettings.globalprofiles = {}  --reform it anew each time  --this shouldnt destroy it!  the reference to each profile still exists!  in the theonetable!  bah.

	for i = 1,#theonetable do
		if(theonetable[i].isglobal) and (theonetable[i].profilename) then
			table.insert(TMAsettings.globalprofiles,theonetable[i])
		end
	end



   if TMAprofileframe and TMAprofileframe:IsVisible() then

		TMAsettings.profilepoints = {}
		TMAsettings.profilepoints.top = floor(TMAprofileframe:GetTop())
		TMAsettings.profilepoints.bottom = floor(TMAprofileframe:GetBottom())
		TMAsettings.profilepoints.left = floor(TMAprofileframe:GetLeft())
		TMAsettings.profilepoints.right = floor(TMAprofileframe:GetRight())

   end


	TMAprofiles.sortmethodnum = TMAsortmethodnum
	TMAsettings.collapseall = TMAcollapseall
   TMAsettings.hidegamemenubutton=TMAhidegamemenubutton
   TMAsettings.grouping = TMAgrouping
   TMAsettings.hidetooltips = TMAhidetooltips
   --TMAsettings.copybyref = TMAcopybyref
   TMAsettings.altlayout = TMAaltlayout

   --TMAprint("End |c0044eeffSaving settings.")
end


------------------------------------------------------------------------------
-- FMCODE - using blizzards tooltips
function TMAshowtooltip(frame,notes)
	if not (TMAhidetooltips) then
	   if frame:GetRight() >= (GetScreenWidth() / 2) then
			GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
		else
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
		end
		if(notes) then
			GameTooltip:SetText(notes, .5, 1, 1, 1, 1)
			GameTooltip:Show()
		end
	end
end

function TMAhidetooltip()
	GameTooltip:Hide()
end
-- /FMCODE
------------------------------------------------------------------------------

function TMAgetprofilenum(name)
	--takes a profile name, turns it into the corresponding number
	local i

	for i = 1,#theonetable do
		if(theonetable[i].profilename == name) then
			return i
		end
	end

   return nil
end

function TMAloadprofile(profile)
    local i,j
    local thealwaysprofilenum, j, name,title,profile1,profile2,isglobal,profilenum

	if(profile and (type(profile) == "string")) then  --done via the /slash command
		profilenum = TMAgetprofilenum(profile)
		if (not profilenum) then
			return false
		end;
	end

	----------past this point, we must ReloadUI()
	--turn off all addons
	for i=1,GetNumAddOns() do
	   DisableAddOn(i)
	end

	thealwaysprofilenum = TMAgetprofilenum(TMAALWAYSPROFILE)
	if (thealwaysprofilenum) then  --they might have deleted it - but it will be back mwahahahahah
	   for i=1,GetNumAddOns() do
		  name,_,_, _, _, _, _ = GetAddOnInfo(i)
		  if(theonetable[thealwaysprofilenum][name]) then
			  EnableAddOn(i)
		  end
	   end
	end


	if(profile and (type(profile) == "string")) then  --done via the /slash command
		profilenum = TMAgetprofilenum(profile)
		if (profilenum) then  --they might have deleted it - but it will be back mwahahahahah
		   for i=1,GetNumAddOns() do
			  name,_,_, _, _, _, _ = GetAddOnInfo(i)
			  if(theonetable[profilenum][name]) then
				  EnableAddOn(i)
			  end
		   end
		end

		for i = 1,#theonetable do
			theonetable[i].isselected = false
		end
		theonetable[profilenum].isselected = true
	else --the clicked the load button

		for i=1,#theonetable do
			if(theonetable[i].isselected) then
				for j=1,GetNumAddOns() do
					name,_,_, _, _, _, _ = GetAddOnInfo(j)
					if(theonetable[i][name]) then
						EnableAddOn(j)
					end
				end
			end
		end
	end

	--store what we loaded so its green next time
	TMAlastgloballoaded = {}
	for i = 1,#theonetable do
		if(theonetable[i].isglobal) then
			if(theonetable[i].isselected) then
				table.insert(TMAlastgloballoaded,theonetable[i].profilename)
			end
		else
			theonetable[i].islastloaded = theonetable[i].isselected
		end
	end
	TMAsavesettings()

	if (TMAdebug) and (IsControlKeyDown() or IsShiftKeyDown()) then
		ReloadUI()

	elseif(TMAdebug) then
		TMAprint("TESTING.  Ctrl or shift down to RELOaD()")
		TMAprint(theonetable)
		--EnableAddOn("TooManyAddons")
	else
		ReloadUI()

	end
end

function TMAcreatenewprofile(isglobal)
	local scrollbar,smin,smax
	local profilename

	if(isglobal == true) then

		profilename = TMAnewglobalprofileeditbox:GetText()
		--clear all the other selected ones
		for i=1,#theonetable do
			theonetable[i].isselected = false
		end

		theonetable[#theonetable].profilename = profilename
		theonetable[#theonetable].isglobal = true
		theonetable[#theonetable].isselected = true
		TMAnewglobalprofileeditbox:SetText("")
		scrollbar = getglobal(TMA_GLOBAL_PROFILE_LIST_NAME.."scrollbarScrollBar")

	else


		--clear all the other selected ones
		for i=1,#theonetable do
			if(theonetable[i] and theonetable[i].isselected) then
				theonetable[i].isselected = false
			end
		end


		theonetable[#theonetable+1] = {}
		profilename = TMAnewprofileeditbox:GetText()
		if not profilename then profilename = "" end;
		theonetable[#theonetable].profilename = profilename
		theonetable[#theonetable].isglobal = false
		theonetable[#theonetable].isselected = true
		TMAnewprofileeditbox:SetText("")
		scrollbar = getglobal(TMA_PROFILE_LIST_NAME.."scrollbarScrollBar")


	end
	TMAupdate()
	smin,smax = scrollbar:GetMinMaxValues()
	scrollbar:SetValue(smax) --since the profile should always be added at the end, its ok to scroll to the end

end
function TMAdeleteprofile()
	local temptable = {}


	for i=1,#theonetable do
		if not (theonetable[i].isselected) then
			table.insert(temptable,theonetable[i])
		end
	end
	theonetable = temptable
	theonetable[#theonetable].isselected=true

	TMAupdate()
end

function TMAsetall(newvalue)
	local profile,i,j


	--if no value is passed in, newvalue contains a table for some reason
	if not (newvalue == true) then
		newvalue = false
	end

	for i=1,#theonetable do
		if(theonetable[i].isselected) then
			profile = theonetable[i]
			for j=1,GetNumAddOns() do
				name,_,_, _, _, _, _ = GetAddOnInfo(j)
				profile[name] = newvalue
			end
		end
	end
	TMAupdate()
end


function TMA_tcopy(to, from)   -- "to" must be a table  -- tcopy: recursively copy contents of one table to another.  from wowwiki
   for k,v in pairs(from) do
     if(type(v)=="table") then
       to[k] = {}
       TMA_tcopy(to[k], v);
     else
       to[k] = v;
     end
   end
 end

function TMAsanitize(str)

    str = string.lower(str)
    str = string.gsub(str,'|c........',"")
    str = string.gsub(str,'|r',"")
    str = string.gsub(str,'[^a-z]',"")
    return str
end
 --
-- Decorator Pattern Text Colorization Functions
-- Same as crayonlib
--
local CLR = {}
CLR.COLOR_NONE = nil
function CLR:Colorize(hexColor, text)
    if text == nil then text = "" end
    if hexColor == CLR.COLOR_NONE then
        return text
    end
    return "|cff" .. tostring(hexColor or 'ffffff') .. tostring(text) .. "|r"
end

function CLR:Label(txt) return CLR:Colorize('ffff7f', txt) end
function CLR:Red(txt) return CLR:Colorize('cc0000', txt) end
function CLR:Green(txt) return CLR:Colorize('00ee00', txt) end

function TMAHideAddonTooltip()
    GameTooltip:Hide()
end

--thank you addon control panel
function TMAShowAddonTooltip(frame)



	if not (TMAhidetooltips) then
		local index = frame.addonnumber
		if not index then return end
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(index)
		local author = GetAddOnMetadata(name, "Author")
		local deps = { GetAddOnDependencies(index) }

		local present_in = {}
		local present_in_text = "NONE"

		GameTooltip:SetOwner(frame)
		if title then
		  GameTooltip:AddLine(title)
		else
		  GameTooltip:AddLine(name, 1,0.78,0,1)
		end
		if notes then
			GameTooltip:AddLine(notes,1,1,1,1) --1111 for word wrapping
		end
		if author then
			GameTooltip:AddLine(string.format("%s: %s", CLR:Label("Author"), author))
		end
		if enabled then
			GameTooltip:AddLine(string.format("%s: %s", CLR:Label("Status"), "Enabled"))
		else
			GameTooltip:AddLine(string.format("%s: %s", CLR:Label("Status"), CLR:Red("Disabled")))
		end
		if(TMAsettings.dates[name]) then
			local tmadate = tostring(TMAsettings.dates[name])
			GameTooltip:AddLine(string.format("%s: %s/%s/%s", CLR:Label("Date First Seen"), string.sub(tmadate,3,4), string.sub(tmadate,5,6),string.sub(tmadate,1,2)))
		end

		local depLine
		local dep = deps[1]
		if dep then
			depLine = CLR:Label("Dependencies")..": "..dep
			for i = 2, #deps do
				dep = deps[i]
				if dep and dep:len()>0 then
					depLine = depLine..", "..dep
				end
			end
			GameTooltip:AddLine(depLine,1,1,1,1)
		end

		UpdateAddOnMemoryUsage()
		local mem = GetAddOnMemoryUsage(index)
		local text2
		if (mem > 0) then
			if mem > 1024 then
				text2 = ("|cff8080ff%.2f|r MB"):format(mem / 1024)
			else
				text2 = ("|cff8080ff%.0f|r KB"):format(mem)
			end

			GameTooltip:AddLine(CLR:Label("Memory Usage")..": "..text2, 1,0.78,0, 1)
		end


		for aidx = 1, #theonetable do
      if theonetable[aidx][name] then
        table.insert(present_in, CLR:Green(theonetable[aidx]["profilename"]))
      end
		end
    if #present_in > 0 then
      present_in_text = table.concat(present_in, ", ")
    end
		GameTooltip:AddLine(CLR:Label("In Profiles")..": "..present_in_text,1,1,1,1)

		GameTooltip:Show()
	end

end






function TMAprofilelistbutton_onclick(self)
	TMAprint("|c00aaeeaaOnclick profile row")
	local start,finish
	local isglobal,profiles

	if not (TMAprevselected) then
		TMAprevselected=self.number
	end

	if (IsShiftKeyDown()) then
		if not (IsControlKeyDown()) then
			--clear all
			for i = 1,#theonetable do
				theonetable[i].isselected = false
			end

		end
		start = math.min(TMAprevselected,self.number)
		finish=math.max(TMAprevselected,self.number)

		for i = start,finish do
			if(theonetable[i]) then
				theonetable[i].isselected = true
			end
		end

	else
		if not (IsControlKeyDown()) then
			--erase everything  --cant just do a = {} as that created a new table reference
			for i = 1,#theonetable do
				theonetable[i].isselected = false
			end
		end
		if (theonetable[self.number]) then
			theonetable[self.number].isselected = not theonetable[self.number].isselected
		end

	end

	TMAprevselected = self.number

	TMAupdate()
end

function TMAaddonlistbutton_onclick(self)

	if (self.name) then


		local newvalue
		local addonname = self.name
		local profile
		local i

		--get the new value of what it should be
		for i = 1,#theonetable do
			if (theonetable[i].isselected) then
				profile=theonetable[i]
				newvalue = not profile[addonname] --if multiple profiles are clicked, just use the value of the first selected profile
				break
			end
		end

		for i = 1,#theonetable do
			if (theonetable[i].isselected) then  --for each checked profile
				theonetable[i][addonname] = newvalue
				--do we need to expand its group
				TMAsetkids(self,i)
				if(newvalue) then  --dont bother if its false
					TMAsetdependencies(addonname,i)
				end
			end
		end


		TMAupdate()

	end  --end this.name
end




function TMAsetkids(self,profilenum)
	if(not TMAgrouping) or (not TMAgroups) then return false end;
	if not profilenum then profilenum = 1 end;

	local addonname = self.name
	local headervalue, kids

	prefix = string.sub(addonname,1,TMACHARSTOCOMP)
	if(TMAisheader(addonname)) then
		headervalue = theonetable[profilenum][addonname]
		kids = TMAgroups[prefix].kids

		for i = 1,#kids do
			theonetable[profilenum][kids.name] = headervalue
		end

	end

end

function TMAsetdependencies(addonname,profilenum)
	TMAprint("|c000044dd SetDependancies reached. addonname="..tostring(addonname)..", profile ="..tostring(profilenum))
	local deps = {}
	local profile
	deps = {GetAddOnDependencies(addonname)}

	if(deps) then
		profile = theonetable[profilenum]
		TMAprint(deps)
		for i = 1,#deps do
			if(not profile[deps[i]]) then  --to prevent infinite loops where 2 things depend each other
				profile[deps[i]] = true  --dont 'uncheck' dependancies, in case some  other mod needs it for a dependancy
				TMAsetdependencies(deps[i],profilenum)  --recursively check dependancies
			end
		end
	end
end
function TMAonenterfunction(self)
	local tooltip
	if(IsControlKeyDown()) then
		TMAshowtooltip(self,"Changes to the addon list will affect all selected profiles.")
	elseif(IsShiftKeyDown()) then
		TMAshowtooltip(self,"Click to select everything between here and your previous click.")
	else
		if(self.tooltip) then
			tooltip = self.tooltip
		else
			tooltip = "Hold Ctrl or Shift to select multiple or groups of profiles."
		end
		TMAshowtooltip(self,tooltip)
	end

	if(TMAmovingbutton) then  --mouse is being held down

		TMAtonumber = self.buttonnumber

		self:SetHighlightTexture("") --disable highlight

		if(not TMAmovetoindicator) then
			TMAmovetoindicator = CreateFrame("Button","TMAmovetoindicator",ourframe)
		end
		TMAmovetoindicator:Show()
		TMAmovetoindicator:SetHeight(2)
		TMAmovetoindicator:SetWidth(self:GetWidth())
		TMAmovetoindicator:SetPoint("bottom",self,"top")

		--TMAmovetoindicator:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		--TMAmovetoindicator:SetNormalTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")

		TMAmovetoindicator:SetBackdrop({bgFile = "Interface\\QuestFrame\\UI-QuestLogTitleHighlight",
							edgeFile="",
							tile = true,
							tilesize = 100,
							edgesize = 0,
							insets = { left = 0, right = 0, top = 0, bottom = 0 }})
		TMAmovetoindicator:SetBackdropColor(1,1,1,1)
		TMAmovetoindicator:SetFrameStrata("TOOLTIP")

	end
end

function TMAswitchtoglobalorlocal()
	TMAprint("|c00ffffddMake global clicked."  )

	for i = 1,#theonetable do
		if(theonetable[i].isselected) then
			theonetable[i].isglobal = not theonetable[i].isglobal
		end
	end

	TMAupdate()  --god damn that was soo omuch easier

end

function TMAaddenabledaddons_onclick()
	local enabled,name,title,i,j
	for i=1, GetNumAddOns() do
		name,title,_, enabled, _, _, _ = GetAddOnInfo(i)
		if(name and enabled) then
			for i=1,#theonetable do
				if(theonetable[i].isselected) then
					theonetable[i][name] = enabled
				end
			end
		end
	end
	TMAupdate()
end













 function TMAmovelistbutton(orignumber,insertat)
	TMAprint("|c00aaffffSTART of function MOVELISTBUTTON().  Insertat = "..tostring(insertat).."  orignumber = "..tostring(orignumber))
	local name = TMA_PROFILE_LIST_NAME
	local mouseoverbutton,ourmax
	--find the button the mouse is on - that is the destination, unless one was explicitly passed in as a parameter
	if(not insertat) then
		local mouseoverbutton = GetMouseFocus()
		if(mouseoverbutton and mouseoverbutton.buttonnumber) then

		   local TMAscrollbar = getglobal(TMA_ADDON_LIST_NAME.."scrollbarScrollBar")
		   TMAprint("Insertat needs to be created. ".."   mouseoverbutton.buttonnumber="..tostring(mouseoverbutton.buttonnumber).."   mouseoverbutton.number="..tostring(mouseoverbutton.number).."  "..tostring(insertat).."  orignumber = "..tostring(orignumber))
		   insertat = mouseoverbutton.buttonnumber
		else
			TMAprint("No insertat passed in.   No mouseoverfocus() found.  error i think.")
		   return false
		end
	else
		TMAprint("passed in Insertat = "..tostring(insertat).."  orignumber = "..tostring(orignumber))
	end

	--if no moving happened
	if(insertat == orignumber) then
	   return false
	end

	 if( not theonetable) then
		TMAprint("The onetable is not found.  wny not?  X_X")
		return false
	end

	ourmax = #theonetable

	if (insertat > ourmax) then
		insertat = ourmax+1
	end
	--get the value we want to move
	TMAmoveme={}
	if(theonetable[orignumber]) then  -- nil when you try to drag an empty box
		TMA_tcopy(TMAmoveme,theonetable[orignumber])
	else
	   return false
    end

	TMAprint(TMAmoveme)

	--now, if we moved a button up (backwards, lower numbers), we have to delete the original first, then insert
	-- if we moved a button down (below), we insert first, delete second
   if (insertat > orignumber) then  --we moved down the list
   	  table.insert(theonetable,insertat,TMAmoveme)
   	  table.remove(theonetable, orignumber)
   else
   	   table.remove(theonetable, orignumber)
   	   table.insert(theonetable,insertat,TMAmoveme)
   end

   TMAhidetooltip()
   TMAupdate()
   return true
end

 TMA_onload()
