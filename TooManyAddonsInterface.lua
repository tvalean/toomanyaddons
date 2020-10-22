--TMAdebug = true

TMAprintstack = -1
function TMAprint(message)
   if(TMAdebug) then
      local stack, filler

      TMAprintstack=TMAprintstack+1
      local filler=""
      for stack=1,TMAprintstack do
	  	 filler=filler.."--"
      end
	  if not message then
	  	 DEFAULT_CHAT_FRAME:AddMessage(filler.."Nil or False")
		 TMAprintstack=TMAprintstack-1
		 return false
      end
      if (type(message) == "table") then
	  	-- DEFAULT_CHAT_FRAME:AddMessage("its a table.  length="..TMA_tcount(message))
	 	local i
	 	for k,v in pairs(message) do

	    	DEFAULT_CHAT_FRAME:AddMessage(filler.."(key)   "..k)
	    	TMAprint(v)
	 	end
      elseif (type(message) == "userdata") then

      else
	  	  if(TMAprintstack>0) then
	    	 DEFAULT_CHAT_FRAME:AddMessage(filler.."(value) "..tostring(message))
	 	 else
	    	 DEFAULT_CHAT_FRAME:AddMessage(filler..tostring(message))
	 	 end
	end
      TMAprintstack=TMAprintstack-1
   end
end



TMA_FRAME_HEIGHT = 453  --had to halve this, for there are now 2 profile frames.  Also add the value of TMA_BUTTON_VERT_OFFSET
TMA_FRAME_WIDTH = 250
TMA_FRAME_WIDTH_ADDON = 500
TMA_BUTTON_VERT_OFFSET = -5  -- Shift button text down slightly so it lines up better with checkbox
TMA_HEIGHT_OF_BUTTON = 30
TMA_GROUPING_BUTTON_WIDTH = 0
TMA_COLUMN_WIDTH = 180
TMA_GAP_BETWEEN_BUTTONS = 10
TMA_ROW_HEIGHT = TMA_HEIGHT_OF_BUTTON - TMA_GAP_BETWEEN_BUTTONS
TMA_ROWS_THAT_CAN_FIT = math.floor(TMA_FRAME_HEIGHT / TMA_ROW_HEIGHT)
TMA_ADDON_LIST_NAME = "TMAaddonlist"
TMA_PROFILE_LIST_NAME = "TMAprofilelist"
TMA_GLOBAL_PROFILE_LIST_NAME = "TMAglobalprofilelist"
TMAALWAYSPROFILE = "Always Load These Addons"
--TMAGLOBALALWAYSPROFILE = "Always Always Load These Addons"
TMACHARSTOCOMP = 4
TMAADDONSTOMAKEAGROUP = 3

TMACTRLTOOLTIP="Changes to the addon list will affect all selected profiles."
TMASHIFTTOOLTIP="Click to select everything between here and your previous click."
TMADEFAULTTOOLTIP="Hold Ctrl or Shift to select multiple or groups of profiles."


function TMAcreateinterface()
	-- create our frames
	TMAcreatechecklist(TMA_ADDON_LIST_NAME)
	TMAcreatechecklist(TMA_PROFILE_LIST_NAME)
	TMAcreatechecklist(TMA_GLOBAL_PROFILE_LIST_NAME)

	local TMAaddonframe = getglobal(TMA_ADDON_LIST_NAME.."frame")
	local TMAprofileframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")
	local TMAglobalprofileframe = getglobal(TMA_GLOBAL_PROFILE_LIST_NAME.."frame")

	--wowwiki says this will make frames closable with 'esc'
	tinsert(UISpecialFrames,TMAaddonframe:GetName());
	tinsert(UISpecialFrames,TMAprofileframe:GetName());
	tinsert(UISpecialFrames,TMAglobalprofileframe:GetName());


	TMAaddonframe:SetHeight(TMA_FRAME_HEIGHT + 90)
	TMAaddonframe:SetWidth(TMA_FRAME_WIDTH_ADDON)
	TMAaddonframe:SetPoint("topleft",TMAprofileframe,"topright", 150,0)
	--broken in 7.1  :(
	--TMAaddonframe:CreateTitleRegion()
	--local titleframe = TMAaddonframe:GetTitleRegion()
	--titleframe:SetText("Your Addons")
	--titleframe:SetPoint("top")
	--titleframe:SetHeight(20)
	--titleframe:SetWidth(50)
	
	TMAprofileframe:SetMovable(true)
	TMAprofileframe:EnableMouse(true)
	TMAaddonframe:SetMovable(false)
	TMAaddonframe:EnableMouse(false)

	TMAglobalprofileframe:SetHeight(100)
	TMAglobalprofileframe:SetWidth(TMA_FRAME_WIDTH)
	TMAglobalprofileframe:SetPoint("topleft",TMAprofileframe,"bottomleft", 0,-90)


	local ourscrollbar = getglobal(TMA_PROFILE_LIST_NAME.."scrollbar")


	TMAaddonframe:Hide()
	TMAprofileframe:Hide()

	local name, title, enabled

------ clear all button
		TMAclearallbutton = CreateFrame("Button",nil,TMAaddonframe,"UIPanelButtonTemplate")
			TMAclearallbutton:SetHeight(32)
			TMAclearallbutton:SetWidth(100)
			TMAclearallbutton:SetText("Clear All")
			TMAclearallbutton:SetPoint("TOPleft",TMAaddonframe,"Topright",25,-32)
			TMAclearallbutton:SetScript("OnClick",function()
				if(IsControlKeyDown()) then
					TMAsetall()
				end
			end)
			TMAclearallbutton:SetScript("OnEnter",function(self)
				TMAshowtooltip(self,"Uncheck all addons.  Requires 'Ctrl' held.")
			end)
			TMAclearallbutton:SetScript("OnLeave",TMAtooltiphide)

------- enable all button
		TMAenableallbutton = CreateFrame("Button",nil,TMAaddonframe,"UIPanelButtonTemplate")
			TMAenableallbutton:SetHeight(32)
			TMAenableallbutton:SetWidth(100)
			TMAenableallbutton:SetText("Enable all")
			TMAenableallbutton:SetPoint("TOP",TMAclearallbutton,"bottom",0,-32)
			TMAenableallbutton:Enable()
			TMAenableallbutton:SetScript("OnClick",function()
				TMAsetall(true)
			end)

---------------------  'use current addons' button
		TMAresetbutton = CreateFrame("Button",nil,TMAaddonframe,"UIPanelButtonTemplate")
			TMAresetbutton:SetHeight(32)
			TMAresetbutton:SetWidth(100)
			TMAresetbutton:SetText("Add Enabled")
			TMAresetbutton:SetPoint("TOP",TMAenableallbutton,"bottom",0,-32)
			TMAresetbutton:SetScript("OnEnter",function(self)
                TMAshowtooltip(self,"Add currently enabled addons to the profile.")
            end)
			TMAresetbutton:SetScript("OnLeave",function()
                TMAhidetooltip()
            end)
			TMAresetbutton:SetScript("OnClick",function()
				TMAaddenabledaddons_onclick()

			end)

------------ create new profile button
		TMAcreatenewprofilebutton = CreateFrame("Button",nil,TMAprofileframe,"UIPanelButtonTemplate")
		TMAcreatenewprofilebutton:SetHeight(32)
		TMAcreatenewprofilebutton:SetWidth(120)
		TMAcreatenewprofilebutton:SetText("New Local Profile")
		TMAcreatenewprofilebutton:SetNormalFontObject("GameFontNormalSmall");
		TMAcreatenewprofilebutton:SetHighlightFontObject("GameFontHighlightSmall");
		TMAcreatenewprofilebutton:SetPoint("bottomLEFT",TMAprofileframe,"Topleft",0,0)
		--TMAcreatenewprofilebutton:SetPoint("TOPLEFT")
		TMAcreatenewprofilebutton:SetScript("OnClick",function()
			TMAcreatenewprofile()

		end)

-- -------------------------the edit box
		TMAnewprofileeditbox = CreateFrame("EditBox",nil,TMAprofileframe,"InputBoxTemplate")
			TMAnewprofileeditbox:SetFocus()
			TMAnewprofileeditbox:SetAutoFocus(false)
			TMAnewprofileeditbox:SetHeight(32)
			TMAnewprofileeditbox:SetWidth(100)
			TMAnewprofileeditbox:SetText("Profile")
			TMAnewprofileeditbox:SetPoint("LEFT",TMAcreatenewprofilebutton,"RIGHT",4,0)
			TMAnewprofileeditbox:SetFrameLevel(3)
			TMAnewprofileeditbox:SetScript("OnEscapePressed",function()
				TMAnewprofileeditbox:ClearFocus()
				TMAupdate()
			end)
			TMAnewprofileeditbox:SetScript("OnEnterPressed",function()
				TMAcreatenewprofilebutton:Click()

			end)
			TMAnewprofileeditbox:SetScript("OnEditFocusGained",function()
					TMAnewprofileeditbox:SetText("")
			end)


			------------ create new GLOBAL profile button
		TMAcreatenewglobalprofilebutton = CreateFrame("Button",nil,TMAglobalprofileframe,"UIPanelButtonTemplate")
		TMAcreatenewglobalprofilebutton:SetHeight(32)
		TMAcreatenewglobalprofilebutton:SetWidth(120)
		TMAcreatenewglobalprofilebutton:SetText("New Global Profile")
		TMAcreatenewglobalprofilebutton:SetPoint("bottomLEFT",TMAglobalprofileframe,"Topleft",0,0)
		TMAcreatenewglobalprofilebutton:SetNormalFontObject("GameFontNormalSmall");
		TMAcreatenewglobalprofilebutton:SetHighlightFontObject("GameFontHighlightSmall");
		--TMAcreatenewglobalprofilebutton:SetPoint("TOPLEFT")
		TMAcreatenewglobalprofilebutton:SetScript("OnClick",function()
			TMAcreatenewprofile(true)

		end)

-- -------------------------the edit box for global
		TMAnewglobalprofileeditbox = CreateFrame("EditBox",nil,TMAglobalprofileframe,"InputBoxTemplate")
			TMAnewglobalprofileeditbox:SetFocus()
			TMAnewglobalprofileeditbox:SetAutoFocus(false)
			TMAnewglobalprofileeditbox:SetHeight(32)
			TMAnewglobalprofileeditbox:SetWidth(100)
			TMAnewglobalprofileeditbox:SetText("Global Profile")
			TMAnewglobalprofileeditbox:SetPoint("LEFT",TMAcreatenewglobalprofilebutton,"RIGHT",4,0)
			TMAnewglobalprofileeditbox:SetFrameLevel(3)
			TMAnewglobalprofileeditbox:SetScript("OnEscapePressed",function()
				TMAnewglobalprofileeditbox:ClearFocus()
				TMAupdate()
			end)
			TMAnewglobalprofileeditbox:SetScript("OnEnterPressed",function()
				TMAcreatenewglobalprofilebutton:Click()

			end)
			TMAnewglobalprofileeditbox:SetScript("OnEditFocusGained",function()
					TMAnewglobalprofileeditbox:SetText("")
			end)


------------------------switch to global/local button
		TMAchooseglobalbutton = CreateFrame("button",TMAchooseglobalbutton,TMAprofileframe,"UIPanelButtonTemplate")
		TMAchooseglobalbutton:SetWidth(100)
		TMAchooseglobalbutton:SetHeight(32)
		TMAchooseglobalbutton:SetPoint("topleft",TMAprofileframe,"topright",25,-32)
		TMAchooseglobalbutton:SetText("Global / Local")
		TMAchooseglobalbutton:SetScript("OnClick",function()
				TMAswitchtoglobalorlocal()
						   end)
		TMAchooseglobalbutton:SetScript("OnEnter",function(self)
			TMAshowtooltip(self,self.tooltip)
		end)
		TMAchooseglobalbutton:SetScript("OnLeave",function()
			TMAhidetooltip()
		end)

------------------------------ delete button --------------------------
		TMAdeletebutton = CreateFrame("Button",nil,TMAprofileframe,"UIPanelButtonTemplate")
			TMAdeletebutton:SetHeight(32)
			TMAdeletebutton:SetWidth(100)
			TMAdeletebutton:SetText("Delete Profile")
			TMAdeletebutton:SetPoint("topleft",TMAchooseglobalbutton,"bottomleft",0,-32)
			--TMAdeletebutton:SetPoint("topleft",TMAprofileframe,"bottomright",25,0)
			TMAdeletebutton:SetScript("OnEnter",function(self)
			      TMAshowtooltip(self,"Delete selected profiles.  Requires 'Ctrl' held.")
			end)
			TMAdeletebutton:SetScript("OnLeave",function()
                TMAhidetooltip()
			end)

			TMAdeletebutton:SetScript("OnClick",function()
				if(IsControlKeyDown()) then
					TMAdeleteprofile()
				end
			end)


----------------- load addon button
		TMAloadbutton = CreateFrame("Button",nil,TMAprofileframe,"UIPanelButtonTemplate")
			TMAloadbutton:SetHeight(32)
			TMAloadbutton:SetWidth(100)
			TMAloadbutton:SetText("Load profile")
			TMAloadbutton:SetPoint("TOP",TMAdeletebutton,"bottom",0,-32)
			TMAloadbutton:SetScript("OnClick",function()
			      TMAloadprofile()
			end)
			TMAloadbutton:SetScript("OnEnter",function(self)
			      TMAshowtooltip(self,"Reload your UI, enabling checked addons, and disabling non-checked addons")
			end)
			TMAloadbutton:SetScript("OnLeave",function()
                TMAhidetooltip()
			end)

 	--------------------------- game menu button --------------------------------------

		TMAgamemenubutton = CreateFrame("Button","GameMenuButtonTMAAddOns",GameMenuFrame,"GameMenuButtonTemplate")
			TMAgamemenubutton:SetText("TooManyAddons")
			TMAgamemenubutton:SetPoint("TOP",GameMenuButtonMacros,"bottom",0,-1)
			TMAgamemenubutton:SetPoint("LEFT",GameMenuButtonAddons,"RIGHT",0,-1)

			--an incompatability
			--if(GameMenuButtonMoveAnything) then   --moveanything seems to have moved its button to the bottom of the list :)
--			   TMAgamemenubutton:SetPoint("TOP",GameMenuButtonMoveAnything,"bottom",0,-1)
			--end
			if(myGameMenuButtonReloadUI) then
			   TMAgamemenubutton:SetPoint("TOP",myGameMenuButtonReloadUI,"bottom",0,-1)
			end
			if(GameMenuButtonSuperMacro) then
			   TMAgamemenubutton:SetPoint("TOP",GameMenuButtonSuperMacro,"bottom",0,-1)
			end
			if(GameMenuButtonAddOns) then  --acp
				TMAprint("GameMenuButtonAddOns found  --  booo acp")
			    TMAgamemenubutton:SetText("Too Many Addons")

			end

			TMAgamemenubutton:Hide()
			TMAgamemenubutton:SetScript("OnClick",function()
				-- PlaySound("igMainMenuOption");
				HideUIPanel(GameMenuFrame);
				TMA();
			end)

			TMAoriggamemenuheight = GameMenuFrame:GetHeight()

------------------------ the dropdown menu to load profiles -------------------------
		TMAprint("|c00ff0033 creating dropdownmenu")
		if(TMAincombat) then
			TMAprint("Cant show dropdowns - in combat.")
		else
			TMAimportmenu = CreateFrame("Frame", "TMAimportmenu", TMAprofileframe, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(TMAimportmenu,TMA_FRAME_WIDTH/2,8)
			TMAimportmenu:SetPoint("Top",TMAprofileframe,"bottom",0,0)

			button = getglobal(TMAimportmenu:GetName().."Button")
			button:SetScript("OnEnter",function(self)

					TMAprint("ON ENTER button of dropdwon")

					TMAshowtooltip(self,"Copy profiles from another character")


					--[[
					local message = "The current copying method is by: "
					if (TMAcopybyref) then
						message = message.."|c0000ffaaReference.|r  All changes are propagated across any copies."
					else
						message = message.."|c0000aaffValue.|r  A second, completely independant copy is created."
					end

					TMAshowtooltip(self,message)
					]]

			end)

			button:SetScript("OnLeave",TMAhidetooltip)
		end
		--invisible button for text
		TMAprint("|c00ff00aa creating invisible button for dropdownmenu")
		TMAimportmenubutton = CreateFrame("Button",nil,TMAimportmenu)
		TMAimportmenubutton:SetText("Import Profiles")
		TMAimportmenubutton:SetNormalFontObject(GameFontNormal)
		TMAimportmenubutton:SetPoint("topleft",40,0)
		TMAimportmenubutton:SetWidth(80)
		TMAimportmenubutton:SetHeight(32)
		TMAimportmenubutton:EnableMouse(false)
		TMAimportmenubutton:Disable()





------------------------ the close button [X] ---------------

		TMAclosebutton = CreateFrame("button",nil,TMAprofileframe,"UIPanelButtonTemplate")
		TMAclosebutton:SetWidth(16)
		TMAclosebutton:SetHeight(20)
		TMAclosebutton:SetPoint("TopRight",0,0)
		TMAclosebutton:SetText("x")
		TMAclosebutton:SetScript("OnClick",function()
						      TMAprofileframe:Hide()
						      TMAaddonframe:Hide()
						   end)
		TMAclosebutton:SetScript("OnEnter",function(self)
			TMAshowtooltip(self,"Close")
		end)
		TMAclosebutton:SetScript("OnLeave",function()
			TMAhidetooltip()
		end)


------------------------ the option button [O] ---------------

		TMAoptionbutton = CreateFrame("button",nil,TMAprofileframe,"UIPanelButtonTemplate")
		TMAoptionbutton:SetWidth(16)
		TMAoptionbutton:SetHeight(20)
		TMAoptionbutton:SetPoint("TopRight",TMAclosebutton,"TopLeft",0,0)
		TMAoptionbutton:SetText("O")
		TMAoptionbutton:SetScript("OnClick",function()
						     TMA("option")
						   end)
		TMAoptionbutton:SetScript("OnEnter",function(self)
			TMAshowtooltip(self,"Options")
		end)
		TMAoptionbutton:SetScript("OnLeave",function()
			TMAhidetooltip()
		end)


------------------------ the reset position button [R] ---------------

		TMAresetposbutton = CreateFrame("button",nil,TMAprofileframe,"UIPanelButtonTemplate")
		TMAresetposbutton:SetWidth(16)
		TMAresetposbutton:SetHeight(20)
		TMAresetposbutton:SetPoint("TopRight",TMAoptionbutton,"TopLeft",0,0)
		TMAresetposbutton:SetText("R")
		TMAresetposbutton:SetScript("OnClick",function()
							TMAResetPosition()
						end)
		TMAresetposbutton:SetScript("OnEnter",function(self)
			TMAshowtooltip(self,"Reset Window to default position and widths")
		end)
		TMAresetposbutton:SetScript("OnLeave",function()
			TMAhidetooltip()
		end)



		if(TMAincombat) then
			TMAprint("Cant show dropdowns - in combat.")
		else

			TMAprint("|c00ff0033 creating Sorting dropdownmenu")
			TMAsortMenu = CreateFrame("Frame", "TMAsortMenu", TMAaddonframe, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(TMAsortMenu,TMA_FRAME_WIDTH/2,8)
			TMAsortMenu:SetPoint("Top",TMAaddonframe,"bottom",0,0)
			--invisible button for text
			TMAsortmenubutton = CreateFrame("Button",nil,TMAsortMenu)
			TMAsortmenubutton:SetText("Sort By:")
			TMAsortmenubutton:SetNormalFontObject(GameFontNormal)
			TMAsortmenubutton:SetPoint("topleft",40,0)
			TMAsortmenubutton:SetWidth(80)
			TMAsortmenubutton:SetHeight(32)
			TMAsortmenubutton:Disable()
		end

		--a Collapse All button
		TMAcollapseallbutton = CreateFrame("button","TMAcollapseallbutton",TMAaddonframe)
		TMAcollapseallbutton:SetHeight(20)
		TMAcollapseallbutton:SetWidth(20)
		TMAcollapseallbutton:SetPoint("bottom",TMAaddonframe,"topleft",50,0)
		TMAcollapseallbutton:SetPushedTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Down")
		TMAcollapseallbutton:SetNormalTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Up")
		TMAcollapseallbutton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Up")
		TMAcollapseallbutton:GetHighlightTexture():SetTexCoord(0,.86,0,.86)
		TMAcollapseallbutton:GetNormalTexture():SetTexCoord(0,.86,0,.86)
		TMAcollapseallbutton:GetPushedTexture():SetTexCoord(0,.86,0,.86)
		TMAcollapseallbutton:GetHighlightTexture():SetAllPoints()
		TMAcollapseallbutton:SetAlpha(0.5)
		TMAcollapseallbutton:SetScript("OnClick",function()

			TMAcollapseall = not TMAcollapseall
			if(TMAgroups) then
				for key,value in pairs(TMAgroups) do
					TMAprint("key = "..key)
					TMAgroups[key].collapsed = TMAcollapseall
				end


				TMAupdate()

			end
		end)
		TMAcollapseallbutton:SetScript("OnEnter",function(self)
			if (TMAcollapseall) then
				notes = "Expand all groups"
			else
				notes = "Collapse all groups"
			end
			TMAshowtooltip(self,notes)
		end)
		TMAcollapseallbutton:SetScript("OnLeave",function()
			TMAhidetooltip()
		end)


		TMAcreatepopupoptions()

end  --end make interface

function TMAResetPosition()
	local TMAprofileframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")
	local TMAaddonframe = getglobal(TMA_ADDON_LIST_NAME.."frame")

    TMAprofileframe:SetWidth(TMA_FRAME_WIDTH)
    TMAprofileframe:SetHeight(TMA_FRAME_HEIGHT)
	TMAprofileframe:ClearAllPoints()
	TMAprofileframe:SetPoint("topleft",UIParent,"topleft",100,-100)
	TMAprofileframe:SetPoint("bottomright",UIParent,"topleft",100+TMA_FRAME_WIDTH,-(100+TMA_FRAME_HEIGHT))

    TMAaddonframe:SetWidth((TMA_FRAME_WIDTH_ADDON))
    TMAaddonframe:SetHeight(TMA_FRAME_HEIGHT)
	TMAaddonframe:ClearAllPoints()
	TMAaddonframe:SetPoint("topleft",UIParent,"topleft",100,-100)
	TMAaddonframe:SetPoint("bottomright",UIParent,"topleft",100+TMA_FRAME_WIDTH,-(100+TMA_FRAME_HEIGHT))
	TMAaddonframe:ClearAllPoints()
	TMAaddonframe:SetPoint("topleft", TMAprofileframe, "topright", 150, 0)

	TMAupdate()
end

function TMAcreatepopupoptions()  --not in use yet
	TMApopupoptions = CreateFrame("Frame","TMApopupoptions",UIParent,"BackdropTemplate")
   --TMApopupoptions:SetPoint("TOP","$UIparent","Bottomright")
   --TMApopupoptions:SetHeight((AS_BUTTON_HEIGHT + AS_FRAMEWHITESPACE )* 4) --4 buttons
   TMApopupoptions:SetHeight((25* 1) + (8 * 2))  --1 buttons
   TMApopupoptions:SetWidth(200)
   TMApopupoptions:Hide()
   TMApopupoptions:SetBackdrop({
				 bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				 edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				 tile = true, tileSize = 32, edgeSize = 32,
				 insets = { left = 9, right = 9, top = 9, bottom = 9}
			      })
   TMApopupoptions:SetBackdropColor(0,0,0,2)
   --TMApopupoptions:SetMovable(true)
   TMApopupoptions:EnableMouse(true)
   --[[
   TMApopupoptions:SetScript("OnMouseDown",function()

					  end)
   TMApopupoptions:SetScript("OnMouseUp",function()

					end)
					]]
   TMApopupoptions:SetScript("OnShow",function()
		TMAprint("POP UP is shown!! :)")
		--TMApopupoptions:SetFrameLevel(TMApopupoptions:GetParent():GetFrameLevel()+1)

   end)
   --TMApopupoptions:SetScript("OnEnter",function()     end)
   TMApopupoptions:SetScript("OnLeave",function(self)
	   --TMApopupoptions:Hide()--bah doesnt work right
	   local x,y = GetCursorScaledPosition()
	   ASprint("Cursor x,y="..x..","..y.."  Left, right, bottom, top="..TMApopupoptions:GetLeft()..","..TMApopupoptions:GetRight()..","..TMApopupoptions:GetBottom()..","..TMApopupoptions:GetTop())
	   if(x < TMApopupoptions:GetLeft() or x > TMApopupoptions:GetRight() or y < TMApopupoptions:GetBottom() or y > TMApopupoptions:GetTop()) then
			TMApopupoptions:Hide()
	   end
   end)

   --make a global profile - somehow
   TMAcreateglobalprofilebutton = CreateFrame("Button",nil,TMApopupoptions)
   TMAcreateglobalprofilebutton:SetHeight(25)
   TMAcreateglobalprofilebutton:SetWidth(TMApopupoptions:GetWidth())
   TMAcreateglobalprofilebutton:SetPoint("top",0,-8)
   TMAcreateglobalprofilebutton:SetNormalFontObject("gamefontnormal")
   TMAcreateglobalprofilebutton:SetText("create global profile?")
   TMAcreateglobalprofilebutton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
   --TMAcreateglobalprofilebutton:SetFrameStrata("DIALOG")  --did 5.0 remove this func?
   --TMAcreateglobalprofilebutton:SetBackdropColor(0,0,0,.2)
   TMAcreateglobalprofilebutton:SetScript("OnClick",function(self)
		TMAcreateglobalprofile(self)

   end)


end

function TMAcreateglobalprofile(self)
	TMAprint("Creating global profile")
	TMApopupoptions:Hide()
end


function TMAcreateoptionframe()


	local Frame = CreateFrame("Frame", "TMAoptions");
	local Text = Frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
	Text:SetText("TooManyAddons is a minimalist and fast addon manager for you addon junkies.");
	Text:SetJustifyH("LEFT");
	Text:SetJustifyV("TOP");
	Text:SetPoint("TOPLEFT", 20, -20);
	Text:SetPoint("BOTTOMRIGHT", -20, 0);

	--option1
	local Button,editbox
	Button = CreateFrame("CheckButton", "TMAoption1", Frame, "OptionsCheckButtonTemplate");
	Button:SetPoint("TOPLEFT", 20, -65);
	--Button:SetText("option1")
	getglobal(Button:GetName().."Text"):SetText("Hide Game Menu Button");
	Button.tooltipText = "Hide the 'Addons' button in the game menu"
	Button:SetScript("OnClick",function(self)
		if self:GetChecked()then
			-- PlaySound("igMainMenuOptionCheckBoxOff");
			TMAhidegamemenubutton = true
		else
			-- PlaySound("igMainMenuOptionCheckBoxOn");
			TMAhidegamemenubutton = false
		end

		TMAupdate()
	end);

	--option 2
	Button = CreateFrame("CheckButton", "TMAoption2", Frame, "OptionsCheckButtonTemplate");
	Button:SetPoint("TOPLEFT",TMAoption1,"BottomLeft",0, -25);
	getglobal(Button:GetName().."Text"):SetText("Enable Grouping");
	Button.tooltipText = "Group addons with similar names."
	Button:SetScript("OnClick",function(self)
		if self:GetChecked()then
			-- PlaySound("igMainMenuOptionCheckBoxOff");
			TMAgrouping = true
		else
			-- PlaySound("igMainMenuOptionCheckBoxOn");
			TMAgrouping = false
		end

		TMAupdate()
	end);


	--hide tooltips option 3
	Button = CreateFrame("CheckButton", "TMAoption3", Frame, "OptionsCheckButtonTemplate");
	Button:SetPoint("TOPLEFT",TMAoption2,"BottomLeft",0, -25);
	getglobal(Button:GetName().."Text"):SetText("Disable Tooltips");
	Button.tooltipText = "Too much lag?  Try this."
	Button:SetScript("OnClick",function(self)
		if self:GetChecked()then
			-- PlaySound("igMainMenuOptionCheckBoxOff");
			TMAhidetooltips = true
		else
			-- PlaySound("igMainMenuOptionCheckBoxOn");
			TMAhidetooltips = false
		end
		TMAprint("OPtion 3 clicked.  HideTooltips? |c0000aaff"..tostring(TMAhidetooltips))
		TMAupdate()
	end);

	--[=[
	--hide tooltips option 4  --something to do with global/local profiles
	Button = CreateFrame("CheckButton", "TMAoption4", Frame, "OptionsCheckButtonTemplate");
	Button:SetPoint("TOPLEFT",TMAoption3,"BottomLeft",0, -25);
	getglobal(Button:GetName().."Text"):SetText("Turn on the alt layout");
	Button.tooltipText = "One list?  or two?  I can't decide!  Let's do both!"
	Button:SetScript("OnClick",function(self)
		if self:GetChecked()then
			PlaySound("igMainMenuOptionCheckBoxOff");
			TMAaltlayout = true
			--tricksy and dangerous If someone manually changes the value of the checkbox or variables get erased or something wonkiy like that
			--we're going to .. i forget.  dang, mental ilnesses suck
		else
			PlaySound("igMainMenuOptionCheckBoxOn");
			TMAaltlayout = false
		end
		TMAupdate()
	end);
	]=]
	TMAaltlayout = true




  --version id
  Text = Frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall");
  Text:SetPoint("BOTTOMRIGHT",-13,13);
  Text:SetText("Version "..tostring(GetAddOnMetadata("TooManyAddons","Version")));


  Frame.name = "TooManyAddons";
  InterfaceOptions_AddCategory(Frame);

end

function TMAscrollbar_update(name)

  TMAupdate()

end

function TMAcreateaddonbutton(i)
    local currentcheckbutton,currentcollapsebutton,currentbutton

    currentcheckbutton = TMACreateCheckButton(TMA_ADDON_LIST_NAME,i)
    currentcheckbutton:SetScript("OnClick",function(self)
		TMAaddonlistbutton_onclick(self)
	end)

    currentcheckbutton:SetScript("OnEnter",function(self)
        TMAShowAddonTooltip(self)
    end)
    currentcheckbutton:SetScript("OnLeave",function()
        TMAHideAddonTooltip()
    end)


    --button for text
    currentbutton = TMACreateButton(TMA_ADDON_LIST_NAME,i)
    currentbutton:SetScript("OnEnter",function(self)
        TMAShowAddonTooltip(self)
    end)
    currentbutton:SetScript("OnLeave",function()
        TMAHideAddonTooltip()
    end)

	if (TMAsettings.grouping) then
		--the little +/- button
		collapsebutton = CreateFrame("button","TMAcollapsebutton"..i,currentcheckbutton,"UIPanelButtonTemplate")
		collapsebutton:SetHeight(20)
		collapsebutton:SetWidth(20)
		collapsebutton:SetPoint("left",currentcheckbutton,"right")
		collapsebutton:SetPushedTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Down")
		collapsebutton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Up")
		collapsebutton:SetNormalTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Up") --fix (?) by ArtureLeCoiffeur
		collapsebutton:GetHighlightTexture():SetTexCoord(0,.86,0,.86)
		collapsebutton:GetNormalTexture():SetTexCoord(0,.86,0,.86)
		collapsebutton:GetPushedTexture():SetTexCoord(0,.86,0,.86)
		collapsebutton:GetHighlightTexture():SetAllPoints()
		collapsebutton:SetAlpha(0.5)
		collapsebutton:SetScript("OnClick",function(self)
			if(self.groupname and TMAgroups) then
				local groupname = self.groupname
				if (TMAgroups[groupname].collapsed) then
				   TMAgroups[groupname].collapsed = false
				else
				   TMAgroups[groupname].collapsed = true
				end
				TMAupdate()
			end
		end)
		collapsebutton:SetScript("OnEnter",function(self)
			if(self.groupname and TMAgroups) then
				local notes
				local groupname = self.groupname
				if (TMAgroups[groupname].collapsed) then
					notes = "Expand addons starting with "..groupname
				else
					notes = "Collapse addons starting with "..groupname
				end
				TMAshowtooltip(self,notes)
			end

		end)
		collapsebutton:SetScript("OnLeave",function()
			TMAhidetooltip()
		end)
	end
end

function TMAcreateprofilerows(i)

    local currentcheckbutton = TMACreateCheckButton(TMA_PROFILE_LIST_NAME,i)
    currentcheckbutton:SetScript("OnEnter",function(self)
		TMAonenterfunction(self)
	end)

    currentcheckbutton:SetScript("OnLeave",function()

        TMAhidetooltip()
    end)
    currentcheckbutton:SetScript("OnClick",function(self)
		TMAprofilelistbutton_onclick(self)
	end)


    local currentbutton = TMACreateButton(TMA_PROFILE_LIST_NAME,i)
    currentbutton:SetScript("OnEnter",function(self)
		TMAonenterfunction(self)
    end)

    currentbutton:SetScript("OnLeave",function(self)
		self:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")  --in case moving the button disabled it temorarily
        TMAhidetooltip()
    end)



	currentbutton.buttonnumber = i

	currentbutton:SetScript("OnMouseDown",function(self,button,down)

		TMAmovingbutton = true
		self:LockHighlight()
	--	TMApopupoptions:Show()
	  --compensate for scroll bar
        TMAscrollbar = getglobal(TMA_PROFILE_LIST_NAME.."scrollbarScrollBar")
        --allow drag repositioning of buttons
	    TMAorignumber = self.buttonnumber+TMAscrollbar:GetValue()

	end)

	 currentbutton:SetScript("OnMouseUp",
    	function(self)
			TMAmovingbutton = false
			self:UnlockHighlight()
			if(TMAmovetoindicator) then
				TMAmovetoindicator:Hide()
				TMAmovelistbutton(TMAorignumber,TMAtonumber)
				TMAmovetoindicator = nil  --TMAmovetoindicator will also serve as a sort of boolean
			end
        --	TMAscrollbar_Update()
    	end)


end


function TMAcreateglobalprofilerows(i)

    local currentcheckbutton = TMACreateCheckButton(TMA_GLOBAL_PROFILE_LIST_NAME,i)
    currentcheckbutton:SetScript("OnEnter",function(self)
		TMAonenterfunction(self)
	end)

    currentcheckbutton:SetScript("OnLeave",function()

        TMAhidetooltip()
    end)
    currentcheckbutton:SetScript("OnClick",function(self)
		TMAprofilelistbutton_onclick(self)
    end)

    local currentbutton = TMACreateButton(TMA_GLOBAL_PROFILE_LIST_NAME,i)
    currentbutton:SetScript("OnEnter",function(self)
		TMAonenterfunction(self)
    end)
    currentbutton:SetScript("OnLeave",function()
        TMAhidetooltip()
    end)
	currentbutton:SetScript("OnMouseDown",function(self,button,down)

		TMApopupoptions:SetParent(self)
		if(button =="RightButton") then
			TMApopupoptions:Show()
		end
	end)
end


function TMAcreatechecklist(name)
	if(getglobal(name.."frame")) then
		--this has already been called.
		return getglobal(name.."frame")
	else
	-- make the global frame
		local ourframe = CreateFrame("Frame",name.."frame",UIParent,"BackdropTemplate")
		local myFrameWidth
		if (name == TMA_ADDON_LIST_NAME) then
			myFrameWidth = TMA_FRAME_WIDTH_ADDON
		else
			myFrameWidth = TMA_FRAME_WIDTH
		end
		ourframe:SetWidth(myFrameWidth)
		ourframe:SetHeight(TMA_FRAME_HEIGHT)
		ourframe:SetPoint("TOPLEFT",200,-200)
		ourframe:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
								edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
								tile = false,
								tilesize = 16,
								edgesize = 16,
								insets = { left = 10, right = 10, top = 10, bottom = 10 }})
		ourframe:SetBackdropColor(0,0,0,1)
		ourframe:SetClampedToScreen()
		ourframe:SetResizable(true)
		ourframe:SetMaxResize(myFrameWidth+50,600)
		ourframe:SetMinResize(TMA_FRAME_WIDTH,50)
		ourframe:SetMovable(true)
		ourframe:Hide()
		--create our custom scripts
		ourframe:SetScript("OnShow",function()
			TMAupdate()
		end)
		ourframe:SetScript("OnMouseDown",function()
			ourframe:StartMoving()
		end)
		ourframe:SetScript("OnMouseUp",function()
			ourframe:StopMovingOrSizing()
			TMAupdate()
		end)
        TMAcreatescrollbar(name)
		TMAcreateresizebutton(name)
	end
	return ourframe
end

function TMAcreateresizebutton(name)
	local ourframe=getglobal(name.."frame")


	TMAresizebutton = CreateFrame("Button",name.."resize",ourframe)
	TMAresizebutton:SetHeight(10)
	TMAresizebutton:SetPoint("bottomright",ourframe,"bottomright")
	TMAresizebutton:SetPoint("bottomleft",ourframe,"bottomleft")
	TMAresizebutton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	--TMAresizebutton:SetNormalTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	TMAresizebutton:EnableMouse(true)
	TMAresizebutton:SetScript("OnMouseDown",function()
		ourframe:StartSizing()
	end)
	TMAresizebutton:SetScript("OnMouseUp",function()
		ourframe:StopMovingOrSizing()
		-- Resizing the addon frame unanchors it, so re-anchor it to the profile frame
		local TMAprofileframe = getglobal(TMA_PROFILE_LIST_NAME.."frame")
		local TMAaddonframe = getglobal(TMA_ADDON_LIST_NAME.."frame")
		TMAaddonframe:ClearAllPoints()
		TMAaddonframe:SetPoint("topleft", TMAprofileframe, "topright", 150, 0)
		TMAupdate()
	end)


end

function TMAcreatescrollbar(name)

   --make the scroll bar for the frame
   local ourframe=getglobal(name.."frame")
	local scrollbarframe = CreateFrame("ScrollFrame",name.."scrollbar",ourframe,"UIPanelScrollFrameTemplate")
	--the slider within the frame
	TMAscrollbar = getglobal(scrollbarframe:GetName().."ScrollBar")
	scrollbarframe:SetAllPoints()
	scrollbarframe:SetPoint("left")

   --up button
   local TMAscrollupbutton = getglobal(scrollbarframe:GetName().."ScrollBarScrollUpButton" );
   TMAscrollupbutton:Enable()
   TMAscrollupbutton:SetScript("OnClick",function()
        local ourscrollbar = getglobal(name.."scrollbarScrollBar")
        ourscrollbar:SetValue(ourscrollbar:GetValue() - 1)
   end)
   TMAscrollupbutton:SetScript("OnMouseDown",function()
					      end)
   TMAscrollupbutton:SetScript("OnMouseUp",function()
					    end)

	--down button
   local TMAscrolldownbutton = getglobal(scrollbarframe:GetName().."ScrollBarScrollDownButton" );
   TMAscrolldownbutton:Enable()
   TMAscrolldownbutton:SetScript("OnClick",function()
        local ourscrollbar = getglobal(name.."scrollbarScrollBar")
        ourscrollbar:SetValue(ourscrollbar:GetValue() + 1)
   end)
   TMAscrolldownbutton:SetScript("OnMouseDown",function()
						end)
   TMAscrolldownbutton:SetScript("OnMouseUp",function()
					      end)
   scrollbarframe:SetScript("OnVerticalScroll",function()
       TMAscrollbar_update(name);
   end)

   scrollbarframe:SetScript("OnMouseWheel",function(self,arg1)
      -- i think arg1 is up or down?
      ourscrollbar = getglobal(self:GetName().."ScrollBar")
      ourscrollbar:SetValue(ourscrollbar:GetValue() - (arg1*(TMArowsthatcanfit(name)/2))) --have it scroll half the list each scroll
   end)

   TMAscrollbar:SetScript("OnShow",function()
        TMAscrollbar_update(name)
    end)


   TMAscrollbar:SetValueStep(1)
   TMAcreatescrollbartemplate(scrollbarframe)

end

function TMAcreatescrollbartemplate(ourscrollbar)

   -------------------------------------------------------------------------------
   --- this is my attempt to go the extra step and give our scrollbar some texture
   -------------------------------------------------------------------------------
   TMAtexturetop = ourscrollbar:CreateTexture()
   --   TMAtexturetop:SetHeight(TMA_BUTTON_HEIGHT)
   TMAtexturetop:SetWidth(31)
   TMAtexturetop:SetPoint("topright",29,2)
   TMAtexturetop:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
   TMAtexturetop:SetTexCoord(0,.484375,0,1) --this cuts the texture, taking only the bottomleft part of it, which just happens to fit the top of a scroll bar --thanks to possessions mod for the exact numbers

   TMAtexturebottom = ourscrollbar:CreateTexture()
   TMAtexturebottom:SetWidth(30)
   TMAtexturebottom:SetHeight(106)
   TMAtexturebottom:SetPoint("bottomright",29,-2)
   TMAtexturebottom:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
   TMAtexturebottom:SetTexCoord(.515625,1,0,.4140625) --this cuts the texture, taking only the bottomright part of it, which just happens to fit the bottom of a scroll bar

   TMAtexturemiddle = ourscrollbar:CreateTexture()
   TMAtexturemiddle:SetWidth(30)
   --TMAtexturemiddle:SetHeight(ourscrollbar:GetHeight())
   TMAtexturemiddle:SetPoint("bottomright",29,0)
   TMAtexturemiddle:SetPoint("topright",29,0)

   TMAtexturemiddle:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
   TMAtexturemiddle:SetTexCoord(0,.5,.2,.2) --this cuts the texture, taking only the left

   TMAtexture = ourscrollbar:CreateTexture()
   TMAtexture:SetHeight(25)
   --   TMAtexture:SetWidth(30)
   TMAtexture:SetAllPoints()
   TMAtexture:SetPoint("right",29,45)
   TMAtexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
   TMAtexture:SetTexCoord(0,.4,.8,.8) --this cuts the texture, taking only the left middle part of it
   TMAtexture:Hide()
end
--=======================================================================


function TMACreateButton(name,i)
	local ourframe = getglobal(name.."frame")
	local ournamebutton = CreateFrame("Button",name.."button"..i,ourframe)
		ournamebutton:SetHeight(TMA_ROW_HEIGHT)
		ournamebutton:SetWidth(TMA_COLUMN_WIDTH)
		local ourcheckbutton = getglobal(name.."checkbutton"..i)
		ournamebutton:SetPoint("TOPLEFT",ourcheckbutton,"TOPRIGHT", TMA_GROUPING_BUTTON_WIDTH, TMA_BUTTON_VERT_OFFSET)
		ournamebutton:SetPoint("right",ourframe,"right")
		ournamebutton:SetNormalFontObject(GameFontNormal)
		local myFontObject = ournamebutton:GetNormalFontObject()
		myFontObject:SetJustifyH("LEFT")
		ournamebutton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
		--ournamebutton:SetText("Button "..i)
		ournamebutton:SetScript("OnClick",function()
			local ourcheckbutton = getglobal(name.."checkbutton"..i)
			ourcheckbutton:Click()
		end)

	return ournamebutton
end

function TMACreateCheckButton(name,i)
	local ourframe = getglobal(name.."frame")
	local ourcheckbutton = CreateFrame("CheckButton",name.."checkbutton"..i,ourframe)
		ourcheckbutton:SetDisabledTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
		ourcheckbutton:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
		ourcheckbutton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
		ourcheckbutton:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
		ourcheckbutton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		ourcheckbutton:SetHeight(TMA_HEIGHT_OF_BUTTON)
		ourcheckbutton:SetWidth(ourcheckbutton:GetHeight())
		ourcheckbutton:SetNormalFontObject(GameFontNormal)
		ourcheckbutton.number = i

		-- if its the top of a row
		if (i == 1) then
				--its the first button
				ourcheckbutton:SetPoint("TOPLEFT",10,-10)
		else
			local previousrow= getglobal(name.."checkbutton"..(i-1))
			ourcheckbutton:SetPoint("TOP",previousrow,"BOTTOM",0,TMA_GAP_BETWEEN_BUTTONS)
		end

	return ourcheckbutton
end

function TMArowsthatcanfit(name)

	local ourframe = getglobal(name.."frame")
	local ourheight = ourframe:GetHeight()
	local ourrowheight = TMA_ROW_HEIGHT
	return math.floor(ourheight / ourrowheight) - 1

end


