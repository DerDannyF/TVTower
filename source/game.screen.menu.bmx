﻿SuperStrict
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.label.bmx"
Import "Dig/base.gfx.gui.input.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "common.misc.gamegui.bmx" 'tguigamewindow / chat / ...
Import "game.screen.base.bmx"
Import "game.network.networkhelper.base.bmx"
Import "game.player.boss.bmx"


'MENU: GAME SETTINGS SCREEN
Type TScreen_GameSettings Extends TGameScreen
	Field guiSettingsWindow:TGUIGameWindow
	Field guiAnnounce:TGUICheckBox
	Field gui24HoursDay:TGUICheckBox
	Field guiSpecialFormats:TGUICheckBox
	Field guiFilterUnreleased:TGUICheckBox
	Field guiGameTitleLabel:TGuiLabel
	Field guiGameTitle:TGuiInput
	Field guiStartYearLabel:TGuiLabel
	Field guiStartYear:TGuiInput
	Field guiButtonStart:TGUIButton
	Field guiButtonBack:TGUIButton
	Field guiChatWindow:TGUIChatWindow
	Field guiPlayerNames:TGUIinput[4]
	Field guiChannelNames:TGUIinput[4]
	Field guiDifficulty:TGUIDropDown[4]
	Field guiFigureArrows:TGUIArrowButton[8]
	Field guiGameSeedLabel:TGuiLabel
	Field guiGameSeed:TGUIinput
	Field modifiedPlayers:Int = False
	Field modifiedGameOptions:Int = False

	Field PlayerDetailsTimer:Long = 0
	Field OptionsTimer:Long = 0

	Global headerSize:Int = 35
	Global guiSettingsPanel:TGUIBackgroundBox
	Global guiPlayersPanel:TGUIBackgroundBox
	Global settingsArea:TRectangle = New TRectangle.Init(10,10,780,0) 'position of the panel
	Global playerBoxDimension:TVec2D = New TVec2D.Init(165,177) 'size of each player area
	Global playerColors:Int = 10
	Global playerColorHeight:Int = 10
	Global playerSlotGap:Int = 25
	Global playerSlotInnerGap:Int = 10 'the gap between inner canvas and inputs

	Field nameState:TLowerString
	Field settingsState:TLowerString = TLowerString.Create("GameSettings")

	Method Create:TScreen_GameSettings(name:String)
		Super.Create(name)
		SetGroupName("ExGame", "GameSettings")
		
		nameState = TLowerString.Create(name)

		'===== CREATE AND SETUP GUI =====
		guiSettingsWindow = New TGUIGameWindow.Create(settingsArea.position, settingsArea.dimension, name)
		guiSettingsWindow.guiBackground.spriteAlpha = 0.5
		Local panelGap:Int = GUIManager.config.GetInt("panelGap", 10)
		guiSettingsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)

		guiPlayersPanel = guiSettingsWindow.AddContentBox(0,0,-1, int(playerBoxDimension.GetY() + 2 * panelGap))
		guiSettingsPanel = guiSettingsWindow.AddContentBox(0,0,-1, 100)

		guiGameTitleLabel = New TGUILabel.Create(New TVec2D.Init(0, 0), "", TColor.CreateGrey(90), name)
		guiGameTitle = New TGUIinput.Create(New TVec2D.Init(0, 12), New TVec2D.Init(250, -1), "", 32, name)
		guiStartYearLabel = New TGUILabel.Create(New TVec2D.Init(255, 0), "", TColor.CreateGrey(90), name)
		guiStartYear = New TGUIinput.Create(New TVec2D.Init(255, 12), New TVec2D.Init(70, -1), "", 4, name)
		guiGameSeedLabel = New TGUILabel.Create(New TVec2D.Init(330, 0), "", TColor.CreateGrey(90), name)
		guiGameSeed = New TGUIinput.Create(New TVec2D.Init(330, 12), New TVec2D.Init(75, -1), "", 9, name)

		guiGameTitleLabel.SetFont( GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT) )
		guiStartYearLabel.SetFont( GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT) )
		guiGameSeedLabel.SetFont( GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT) )


		Local checkboxHeight:Int = 0
		gui24HoursDay = New TGUICheckBox.Create(New TVec2D.Init(430, 0), New TVec2D.Init(300), "", name)
		gui24HoursDay.SetChecked(True, False)
		gui24HoursDay.disable() 'option not implemented
		checkboxHeight :+ gui24HoursDay.GetScreenHeight()

		guiSpecialFormats = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiSpecialFormats.SetChecked(True, False)
		guiSpecialFormats.disable() 'option not implemented
		checkboxHeight :+ guiSpecialFormats.GetScreenHeight()

		guiFilterUnreleased = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiFilterUnreleased.SetChecked(False, False)
		checkboxHeight :+ guiFilterUnreleased.GetScreenHeight()

		guiAnnounce = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiAnnounce.SetChecked(True, False)


		guiSettingsPanel.AddChild(guiGameTitleLabel)
		guiSettingsPanel.AddChild(guiGameTitle)
		guiSettingsPanel.AddChild(guiStartYearLabel)
		guiSettingsPanel.AddChild(guiStartYear)
		guiSettingsPanel.AddChild(guiGameSeedLabel)
		guiSettingsPanel.AddChild(guiGameSeed)
		guiSettingsPanel.AddChild(guiAnnounce)
		guiSettingsPanel.AddChild(gui24HoursDay)
		guiSettingsPanel.AddChild(guiSpecialFormats)
		guiSettingsPanel.AddChild(guiFilterUnreleased)


		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		guiButtonsWindow = New TGUIGameWindow.Create(New TVec2D.Init(590, 400), New TVec2D.Init(200, 190), name)
		guiButtonsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")


		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)

		TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
		TGUIButton.SetTypeCaptionColor( TColor.CreateGrey(75) )

		guiButtonStart = New TGUIButton.Create(New TVec2D.Init(0, 0), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonBack = New TGUIButton.Create(New TVec2D.Init(0, guiButtonsPanel.GetcontentScreenHeight() - guiButtonStart.GetScreenHeight()), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonBack)


		guiChatWindow = New TGUIChatWindow.Create(New TVec2D.Init(10,400), New TVec2D.Init(540,190), name)
		guiChatWindow.guiChat.guiInput.setMaxLength(200)

		guiChatWindow.guiBackground.spriteAlpha = 0.5
		guiChatWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiChatWindow.guiChat.guiList.Resize(guiChatWindow.guiChat.guiList.rect.GetW(), guiChatWindow.guiChat.guiList.rect.GetH()-10)
		guiChatWindow.guiChat.guiInput.rect.position.addXY(panelGap, -panelGap)
		guiChatWindow.guiChat.guiInput.Resize( guiChatWindow.guiChat.GetContentScreenWidth() - 2* panelGap, guiStartYear.GetScreenHeight())

		For Local i:Int = 0 To 3
			Local slotX:Int = i * (playerSlotGap + playerBoxDimension.GetIntX())
			Local playerPanel:TGUIBackgroundBox = New TGUIBackgroundBox.Create(New TVec2D.Init(slotX, 0), New TVec2D.Init(playerBoxDimension.GetIntX(), playerBoxDimension.GetIntY()), name)
			playerPanel.spriteBaseName = "gfx_gui_panel.subContent.bright"
			playerPanel.SetPadding(playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap)
			guiPlayersPanel.AddChild(playerPanel)

			guiPlayerNames[i] = New TGUIinput.Create(New TVec2D.Init(0, 0), New TVec2D.Init(playerPanel.GetContentScreenWidth(), -1), "player", 16, name)
			guiPlayerNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_player"))

			guiChannelNames[i] = New TGUIinput.Create(New TVec2D.Init(0, 0), New TVec2D.Init(playerPanel.GetContentScreenWidth(), -1), "channel", 16, name)
			guiChannelNames[i].rect.position.SetY(100)
			guiChannelNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_tvchannel"))


			guiDifficulty[i] = New TGUIDropDown.Create(New TVec2D.Init(0, 0), New TVec2D.Init(playerPanel.GetContentScreenWidth(), -1), "Leicht", 16, name)
			guiDifficulty[i].rect.position.SetY(playerPanel.GetContentScreenHeight() - guiDifficulty[i].rect.GetH() + 4)
			local difficultyValues:string[] = ["easy", "normal", "hard"]
			local itemHeight:int = 0
			For local s:string = EachIn difficultyValues
				local item:TGUIDropDownItem = new TGUIDropDownItem.Create(new TVec2D, new TVec2D.Init(100,20), GetLocale("DIFFICULTY_"+s))
				item.data.Add("value", s)

				guiDifficulty[i].AddItem( item )
				If itemHeight = 0 Then itemHeight = item.GetScreenHeight()

				'we want to have max "difficulty-variant" items visible at once
				guiDifficulty[i].SetListContentHeight(itemHeight * Min(difficultyValues.length,5))
			Next


			'left arrow
			guiFigureArrows[i*2 + 0] = New TGUIArrowButton.Create(New TVec2D.Init(0 + 10, 40), New TVec2D.Init(24, 24), "LEFT", name)
			'right arrow
			guiFigureArrows[i*2 + 1] = New TGUIArrowButton.Create(New TVec2D.Init(playerPanel.GetContentScreenWidth() - 10, 40), New TVec2D.Init(24, 24), "RIGHT", name)
			guiFigureArrows[i*2 + 1].rect.position.AddXY(-guiFigureArrows[i*2 + 1].GetScreenWidth(),0)

			playerPanel.AddChild(guiPlayerNames[i])
			playerPanel.AddChild(guiChannelNames[i])
			playerPanel.AddChild(guiDifficulty[i])
			playerPanel.AddChild(guiFigureArrows[i*2 + 0])
			playerPanel.AddChild(guiFigureArrows[i*2 + 1])
		Next


		'set button texts
		'could be done in "startup"-methods when changing screens
		'to the DIG ones
		SetLanguage()


		'===== REGISTER EVENTS =====
		'register changes to GameSettingsStartYear-guiInput
		EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiStartYear)
		'and to game seed
		EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiGameSeed)
		'register checkbox changes
		EventManager.registerListenerMethod("guiCheckBox.onSetChecked", Self, "onCheckCheckboxes", "TGUICheckbox")

		'register changes to player or channel name
		For Local i:Int = 0 To 3
			EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiPlayerNames[i])
			EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiChannelNames[i])
			EventManager.registerListenerMethod("GUIDropDown.onSelectEntry", Self, "onChangeGameSettingsInputs", guiDifficulty[i])
		Next

		'handle clicks on the gui objects
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickButtons", "TGUIButton")
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickArrows", "TGUIArrowButton")

		Return Self
	End Method


	'override to set guielements values (instead of only on screen creation)
	Method Start()
		'assign player/channel names
		For Local i:Int = 0 To 3
			guiPlayerNames[i].SetValue( GetPlayerBase(i+1).name )
			guiChannelNames[i].SetValue( GetPlayerBase(i+1).channelName )

			local selectedDropDownItem:TGUIDropDownItem 
			For Local item:TGUIDropDownItem = EachIn guiDifficulty[i].GetEntries()
				Local s:string = item.data.GetString("value")
				if s = GetPlayerBase(i+1).difficultyGUID
					selectedDropDownItem = item
					Exit
				endif
			Next
			if selectedDropDownItem then guiDifficulty[i].SetSelectedEntry(selectedDropDownItem)
		Next

		guiGameTitle.SetValue(GetGameBase().title)
		guiStartYear.SetValue(GetGameBase().userStartYear)
		guiPlayerNames[0].SetValue(GetGameBase().username)
		guiChannelNames[0].SetValue(GetGameBase().userchannelname)

		SeedRnd(Millisecs())
		guiGameSeed.SetValue( string(Rand(0, 10000000)) )

		GetPlayerBase(1).Name = GetGameBase().username
		GetPlayerBase(1).Channelname = GetGameBase().userchannelname

		guiGameTitle.SetValue(GetGameBase().title)
	End Method



	'handle clicks on the buttons
	Method onClickArrows:Int(triggerEvent:TEventBase)
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent._sender)
		If Not sender Then Return False

		'left/right arrows to change figure base
		For Local i:Int = 0 To 7
			If sender = guiFigureArrows[i]
				local playerID:int = 1+int(Ceil(i/2))
				If i Mod 2  = 0 Then GetPlayerBase(playerID).UpdateFigureBase(GetPlayerBase(playerID).figurebase -1)
				If i Mod 2 <> 0 Then GetPlayerBase(playerID).UpdateFigureBase(GetPlayerBase(playerID).figurebase +1)
				modifiedPlayers = True
			EndIf
		Next
	End Method


	'handle clicks on the buttons
	Method onClickButtons:Int(triggerEvent:TEventBase)
		Local sender:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not sender Then Return False


		Select sender
			Case guiButtonStart
					If Not GetGameBase().networkgame And Not GetGameBase().onlinegame
						TLogger.Log("Game", "Start a new singleplayer game", LOG_DEBUG)

						'set self into preparation state
						GetGameBase().SetGamestate(TGameBase.STATE_PREPAREGAMESTART)
					Else
						TLogger.Log("Game", "Start a new multiplayer game", LOG_DEBUG)
						guiAnnounce.SetChecked(False)
						Network.StopAnnouncing()

						'demand others to do the same
						GetNetworkHelper().SendPrepareGame()
						'set self into preparation state
						GetGameBase().SetGamestate(TGameBase.STATE_PREPAREGAMESTART)
					EndIf

			Case guiButtonBack
					If GetGameBase().networkgame
						Network.StopAnnouncing()

						If Network.isServer
							Network.DisconnectFromServer()
						Else
							Network.client.Disconnect()
						EndIf
						GetPlayerBaseCollection().playerID = 1
						GetPlayerBossCollection().playerID = 1
						GetGameBase().SetGamestate(TGameBase.STATE_NETWORKLOBBY)
						guiAnnounce.SetChecked(False)
					Else
						GetGameBase().SetGamestate(TGameBase.STATE_MAINMENU)
					EndIf
		End Select
	End Method


	Method onCheckCheckboxes:Int(triggerEvent:TEventBase)
		Local sender:TGUICheckBox = TGUICheckBox(triggerEvent.GetSender())
		If Not sender Then Return False

		Select sender
			Case guiFilterUnreleased
					'ATTENTION: use "not" as checked means "not ignore"
					TProgrammeData.setIgnoreUnreleasedProgrammes( not sender.isChecked() )
		End Select

		'only inform when in settings menu
		If GetGameBase().IsGameState(TGameBase.STATE_SETTINGSMENU)
			If sender.isChecked()
				GetGameBase().SendSystemMessage(GetLocale("OPTION_ON")+": "+sender.GetValue())
			Else
				GetGameBase().SendSystemMessage(GetLocale("OPTION_OFF")+": "+sender.GetValue())
			EndIf
		EndIf
	End Method


	Method onChangeGameSettingsInputs(triggerEvent:TEventBase)
		Local sender:TGUIObject = TGUIObject(triggerEvent.GetSender())
		Local value:String = triggerEvent.GetData().getString("value")

		'name or channel changed?
		For Local i:Int = 0 To 3
			if not GetPlayerBase(i+1) then continue
			
			If sender = guiPlayerNames[i] Then GetPlayerBase(i+1).Name = value
			If sender = guiChannelNames[i] Then GetPlayerBase(i+1).channelName = value

			If sender = guiDifficulty[i]
				local item:TGUIDropDownItem = TGUIDropDownItem(guiDifficulty[i].GetSelectedEntry())
				if item
					GetPlayerBase(i+1).SetDifficulty( item.data.GetString("value") )
				endif
			endif
		Next


		if sender = guiGameSeed
			local valueNumeric:string = string(StringHelper.NumericFromString(value))
			if value <> valueNumeric then sender.SetValue(valueNumeric)
			GetGameBase().SetRandomizerBase( int(valueNumeric)  )
		endif


		'start year changed
		If sender = guiStartYear
			GetGameBase().SetStartYear( int(sender.GetValue()) )
			'use the (maybe corrected value)
			TGUIInput(sender).value = GetGameBase().GetStartYear()

			'store it as user setting so it gets used in
			'GetGameBase().PreparewNewGame()
			GetGameBase().userStartYear = int(TGUIInput(sender).value)
		EndIf
	End Method


	'override default
	Method SetLanguage:Int(languageCode:String = "")
		'not needed, done during update
		'guiSettingsWindow.SetCaption(GetLocale("MENU_NETWORKGAME"))

		guiGameTitleLabel.SetValue(GetLocale("GAME_TITLE")+":")
		guiStartYearLabel.SetValue(GetLocale("START_YEAR")+":")
		guiGameSeedLabel.SetValue(GetLocale("GAME")+" #:")

		gui24HoursDay.SetValue(GetLocale("24_HOURS_GAMEDAY"))
		guiSpecialFormats.SetValue(GetLocale("ALLOW_TRAILERS_AND_INFOMERCIALS"))
		guiFilterUnreleased.SetValue(GetLocale("ALLOW_MOVIES_WITH_YEAR_OF_PRODUCTION_GT_GAMEYEAR"))

		guiAnnounce.SetValue("Nach weiteren Spielern suchen")
		
		guiButtonStart.SetCaption(GetLocale("MENU_START_GAME"))
		guiButtonBack.SetCaption(GetLocale("MENU_BACK"))

		guiChatWindow.SetCaption(GetLocale("CHAT"))


		're-align the checkboxes as localization might have changed
		'label dimensions
		Local y:Int = 0
		gui24HoursDay.rect.position.SetY(0)
		y :+ gui24HoursDay.GetScreenHeight()

		guiSpecialFormats.rect.position.SetY(y)
		y :+ guiSpecialFormats.GetScreenHeight()

		guiFilterUnreleased.rect.position.SetY(y)
	End Method
	

	Method Draw:Int(tweenValue:Float)
		DrawMenuBackground(True)

		'background gui items
		GUIManager.Draw(nameState, 0, 100)

		Local slotPos:TVec2D = New TVec2D.Init(guiPlayersPanel.GetContentScreenX(),guiPlayersPanel.GetContentScreeny())
		For Local i:Int = 1 To 4
			'draw colors
			Local colorRect:TRectangle = New TRectangle.Init(slotPos.GetIntX()+2, Int(guiChannelNames[i-1].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)
			For Local pc:TPlayerColor = EachIn TPlayerColor.List
				If pc.ownerID = 0
					colorRect.position.AddXY(colorRect.GetW(), 0)
					pc.SetRGB()
					DrawRect(colorRect.GetX(), colorRect.GetY(), colorRect.GetW(), colorRect.GetH())
				EndIf
			Next

			'draw player figure
			SetColor 255,255,255
			GetPlayerBase(i).GetFigure().Sprite.Draw(Int(slotPos.GetX() + playerBoxDimension.GetX()/2 - GetPlayerBase(i).GetFigure().Sprite.framew / 2), Int(colorRect.GetY() - GetPlayerBase(i).GetFigure().Sprite.area.GetH()), 8)

			If GetGameBase().networkgame
				Local hintX:Int = Int(slotPos.GetX()) + 12
				Local hintY:Int = Int(guiPlayersPanel.GetContentScreeny())+40
				Local hint:String = "undefined playerType"
				If GetPlayerBase(i).IsRemoteHuman()
					hint = "remote player"
				ElseIf GetPlayerBase(i).IsRemoteAI()
					hint = "remote AI"
				ElseIf GetPlayerBase(i).IsLocalAI()
					hint = "local AI"
				ElseIf GetPlayerBase(i).IsLocalHuman()
					hint = "local player"
				EndIf
				GetBitMapFontManager().Get("default", 10).Draw(hint, hintX, hintY, TColor.CreateGrey(100))
			EndIf
			
			'move to next slot position
			slotPos.AddXY(playerSlotGap + playerBoxDimension.GetX(), 0)
		Next

		'overlay gui items (higher zindex)
		GUIManager.Draw(nameState, 101)
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)


		If GetGameBase().networkgame
			If Not GetGameBase().isGameLeader()
				guiButtonStart.disable()
			Else
				guiButtonStart.enable()
			EndIf
			'guiChat.setOption(GUI_OBJECT_VISIBLE,True)
			If Not GetGameBase().onlinegame
				guiSettingsWindow.SetCaption(GetLocale("MENU_NETWORKGAME"))
			Else
				guiSettingsWindow.SetCaption(GetLocale("MENU_ONLINEGAME"))
			EndIf

			guiAnnounce.show()
			guiGameTitle.show()
			guiGameTitleLabel.show()

			If guiAnnounce.isChecked() And GetGameBase().isGameLeader()
			'If GetGame().isGameLeader()
				'guiAnnounce.enable()
				guiGameTitle.disable()
				If guiGameTitle.Value = "" Then guiGameTitle.Value = "no title"
				GetGameBase().title = guiGameTitle.Value
			Else
				guiGameTitle.enable()
			EndIf
			If Not GetGameBase().isGameLeader()
				guiGameTitle.disable()
				guiAnnounce.disable()
			EndIf

			'disable/enable announcement on lan/online
			If guiAnnounce.isChecked()
				Network.client.playerName = GetPlayerBase().name
				If Not Network.announceEnabled Then Network.StartAnnouncing(GetGameBase().title)
			Else
				Network.StopAnnouncing()
			EndIf
		Else
			guiSettingsWindow.SetCaption(GetLocale("MENU_SOLO_GAME"))
			'guiChat.setOption(GUI_OBJECT_VISIBLE,False)


			guiAnnounce.hide()
			guiGameTitle.disable()
		EndIf

		For Local i:Int = 0 To 3
			If GetGameBase().networkgame Or GetGameBase().isGameLeader()
				If not GetGameBase().IsGameState(TGameBase.STATE_PREPAREGAMESTART) And GetGameBase().IsControllingPlayer(i+1)
					guiPlayerNames[i].enable()
					guiChannelNames[i].enable()
					guiFigureArrows[i*2].enable()
					guiFigureArrows[i*2 +1].enable()
				Else
					guiPlayerNames[i].disable()
					guiChannelNames[i].disable()
					guiFigureArrows[i*2].disable()
					guiFigureArrows[i*2 +1].disable()
				EndIf
			EndIf
		Next

		GUIManager.Update(settingsState)


		'not final !
		If KEYMANAGER.isDown(KEY_ENTER)
			If Not GUIManager.GetFocus()
				GUIManager.SetFocus(guiChatWindow.guiChat.guiInput)
				'KEYMANAGER.blockKey(KEY_ENTER, 200) 'block for 100ms
				'KEYMANAGER.resetKey(KEY_ENTER)
			EndIf
		EndIf

		'clicks on color rect
		Local i:Int = 0

	'	rewrite to Assets instead of global list in TColor ?
	'	local colors:TList = Assets.GetList("PlayerColors")

		If MOUSEMANAGER.IsClicked(1)
			Local slotPos:TVec2D = New TVec2D.Init(guiPlayersPanel.GetContentScreenX(),guiPlayersPanel.GetContentScreeny())
			For Local i:Int = 0 To 3
				Local colorRect:TRectangle = New TRectangle.Init(slotPos.GetIntX() + 2, Int(guiChannelNames[i].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)

				For Local pc:TPlayerColor = EachIn TPlayerColor.List
					'only for unused colors
					If pc.ownerID <> 0 Then Continue

					colorRect.position.AddXY(colorRect.GetW(), 0)

					'skip if outside of rect
					If Not THelper.MouseInRect(colorRect) Then Continue
					'only allow mod if you control the player or if the
					'player is AI and you are the master player
					If GetGameBase().IsControllingPlayer(i+1)
						modifiedPlayers = True
						GetPlayerBase(i+1).RecolorFigure(pc)
					EndIf
				Next
				'move to next slot position
				slotPos.AddXY(playerSlotGap + playerBoxDimension.GetX(), 0)
			Next
		EndIf


		If GetGameBase().networkgame = 1
			'sync if the player got modified
			If modifiedPlayers or Time.GetTimeGone() >= PlayerDetailsTimer + 2000
				GetNetworkHelper().SendPlayerDetails()
				PlayerDetailsTimer = MilliSecs()
				modifiedPlayers = False
			EndIf
			If modifiedGameOptions or Time.GetTimeGone() >= OptionsTimer + 2000
				print "NET: TODO - GetNetworkHelper().SendGameOptions()"
				'GetNetworkHelper().SendGameOptions()
				OptionsTimer = MilliSecs()

				modifiedPlayers = False
			endif
		EndIf
	End Method
End Type



Function DrawMenuBackground(darkened:Int=False)
	'cls only needed if virtual resolution is enabled, else the
	'background covers everything
	if GetGraphicsManager().HasBlackBars()
		SetClsColor 0,0,0
		'use graphicsmanager's cls as it resets virtual resolution
		'first
		'Cls()
		GetGraphicsManager().Cls()
	endif

	SetColor 255,255,255
	GetSpriteFromRegistry("gfx_startscreen").Draw(0,0)


	'draw an (animated) logo
	Select ScreenCollection.GetCurrentScreen().name.toUpper()
		Case "NetworkLobby".toUpper(), "MainMenu".toUpper()
			Global logoAnimStart:Int = 0
			Global logoAnimTime:Int = 1500
			Global logoScale:Float = 0.0
			Local logo:TSprite = GetSpriteFromRegistry("gfx_startscreen_logo")
			If logo
				Local timeGone:Int = Time.GetTimeGone()
				If logoAnimStart = 0 Then logoAnimStart = timeGone
				logoScale = TInterpolation.BackOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)
				logoScale :* TInterpolation.BounceOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)

				Local oldAlpha:Float = GetAlpha()
				SetAlpha Float(TInterpolation.RegularOut(0.0, 1.0, Min(0.5*logoAnimTime, timeGone - logoAnimStart), 0.5*logoAnimTime))

				logo.Draw( GetGraphicsManager().GetWidth()/2, 150, -1, ALIGN_CENTER_CENTER, logoScale)
				SetAlpha oldAlpha
			EndIf
	End Select

	If GetGameBase().IsGameState(TGameBase.STATE_MAINMENU)
		SetColor 255,255,255
		GetBitmapFont("Default",13, BOLDFONT).DrawBlock("ACHTUNG neue Tastenkürzel:", 10,460, 300,20, Null,TColor.Create(140,75,75))
		GetBitmapFont("Default",12).DrawBlock("|b|[S]|/b| Schnellspeichern - nun mit |b|[F5]|/b|~n|b|[L]|/b| Schnellspeicherstand einladen - nun mit |b|[F8]|/b|.~nDamit sollten versehentliche Spielverluste durch Einladerei minimiert werden.", 10,480, 300,50, Null,TColor.Create(75,75,75))

rem
		SetColor 255,255,255
		GetBitmapFont("Default",13, BOLDFONT).DrawBlock("Wir brauchen Deine Hilfe!", 10,460, 300,20, Null,TColor.Create(75,75,140))
		GetBitmapFont("Default",12).DrawBlock("Beteilige Dich an Diskussionen rund um alle Spielelemente in TVTower.", 10,480, 300,30, Null,TColor.Create(75,75,140))
		GetBitmapFont("Default",12, BOLDFONT).drawBlock("www.gamezworld.de/phpforum", 10,507, 500,20, Null,TColor.Create(75,75,180))
		SetAlpha 0.5 * GetAlpha()
		GetBitmapFont("Default",11).drawBlock("(Keine Anmeldung notwendig)", 10,521, 500,20, Null,TColor.Create(60,60,150))
		SetAlpha 2.0 * GetAlpha()
endrem

		GetBitmapFont("Default",12, ITALICFONT).drawBlock(versionstring, 10,565, 500,20, Null,TColor.Create(75,75,140))
		GetBitmapFont("Default",12, ITALICFONT).drawBlock(copyrightstring+", www.TVTower.org", 10,580, 500,20, Null,TColor.Create(60,60,120))
	EndIf

	If darkened
		SetColor 190,220,240
		SetAlpha 0.5
		DrawRect(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetAlpha 1.0
		SetColor 255, 255, 255
	EndIf
End Function