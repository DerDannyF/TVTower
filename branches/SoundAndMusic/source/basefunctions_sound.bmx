SuperStrict
Import brl.Map
Import brl.OpenALAudio
'Import brl.FreeAudioAudio
'Import brl.WAVLoader
Import brl.OGGLoader
Import "basefunctions.bmx"

Const MUSIC_TITLE:String					= "MUSIC_TITLE"
Const MUSIC_MUSIC:String					= "MUSIC_MUSIC"

Const SFX_ELEVATOR_DING:String				= "SFX_ELEVATOR_DING"
Const SFX_ELEVATOR_ENGINE:String			= "SFX_ELEVATOR_ENGINE"

Type TSoundManager
	Field soundFiles:TMap = null
	Field musicChannel1:TChannel = null
	Field musicChannel2:TChannel = null
	Field activeMusicChannel:TChannel = null
	Field inactiveMusicChannel:TChannel = null
	
	Field sfxChannel_Elevator:TChannel = null
	Field sfxVolume:float = 1
	Field defaultSfxOptions:TSfxOptions = null
	
	Field musicOn:int = 1
	Field musicVolume:float = 1
	Field nextMusicTitleVolume:float = 1
	Field lastTitleNumber:int = 0
	Field currentMusic:TSound = null
	Field nextMusicTitle:TSound = null
	Field forceNextMusicTitle:int = 0
	Field fadeProcess:int = 0 '0 = nicht aktiv  1 = aktiv
	Field fadeOutVolume:int = 1000
	Field fadeInVolume:int = 0
	
	Field movingElements:TMap = null
	Field receiver:TElementPosition
	
	Function Create:TSoundManager()
		If EnableOpenALAudio() Then
			SetAudioDriver("OpenAL")
		Else
			SetAudioDriver("FreeAudio")	
		End If
		
		
		Local manager:TSoundManager = New TSoundManager
		manager.musicChannel1 = AllocChannel()
		manager.musicChannel2 = AllocChannel()
		manager.activeMusicChannel = manager.musicChannel1
		manager.inactiveMusicChannel = manager.musicChannel2
		manager.sfxChannel_Elevator = AllocChannel()
		manager.defaultSfxOptions = TSfxOptions.Create()
		manager.movingElements = CreateMap()
		Return manager 
	End Function
	
	Method SetDefaultReceiver(_receiver:TElementPosition)
		print "SetDefaultReceiver"
		receiver = _receiver
	End Method

	Method LoadSoundFiles()
		'mv: Alternativ k�nnen die Files auch in einem seperaten Thread geladen werden oder erst bei Bedarf... dann ruckelt's leider aber etwas. Kannst du (Ronny) entscheiden ;)		
		local total:int = 8
				
		Self.soundFiles = CreateMap:TMap()
		LoadProgress(1, total)
		MapInsert( Self.soundFiles, MUSIC_TITLE, LoadSound("res/music/title.ogg", SOUND_LOOP) )
		LoadProgress(2, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "1", LoadSound("res/music/music1.ogg", SOUND_HARDWARE) )
		LoadProgress(3, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "2", LoadSound("res/music/music2.ogg", SOUND_HARDWARE) )
		LoadProgress(4, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "3", LoadSound("res/music/music3.ogg", SOUND_HARDWARE) )
		LoadProgress(5, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "4", LoadSound("res/music/music4.ogg", SOUND_HARDWARE) )
		LoadProgress(6, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "5", LoadSound("res/music/music5.ogg", SOUND_HARDWARE) )						
		'LoadProgress(7, total)
		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "6", LoadSound("res/music/music6.ogg") )
		'LoadProgress(8, total)
		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "7", LoadSound("res/music/music7.ogg") )
		'LoadProgress(9, total)
		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "8", LoadSound("res/music/music8.ogg") )
		'LoadProgress(10, total)
		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "9", LoadSound("res/music/music9.ogg") )

		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "9", LoadSound("res/music/specialroom1.ogg") )		
		'Rnd(1, TRooms.RoomList.Count() - 1)
		
		LoadProgress(7, total)
		MapInsert( Self.soundFiles, SFX_ELEVATOR_DING, LoadSound("res/sfx/elevator_ding.ogg", SOUND_HARDWARE) )
		
		LoadProgress(8, total)
		MapInsert( Self.soundFiles, SFX_ELEVATOR_ENGINE, LoadSound("res/sfx/elevator_engine.ogg", SOUND_LOOP | SOUND_HARDWARE) )
	End Method
	
	Method LoadProgress(currentCount:int, totalCount:int)
		'EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "sound files").AddNumber("itemNumber", currentCount).AddNumber("maxItemNumber", totalCount) ) )
	End Method

	Method Update()
		For Local element:TMovingElementSFX = EachIn MapValues(movingElements)
			element.AdjustSettings()
		Next
	
		If musicOn Then			
			'Wenn der Musik-Channel nicht l�uft, dann muss nichts gemacht werden
			if (Self.activeMusicChannel.Playing()) then			
				if (Self.forceNextMusicTitle and Self.nextMusicTitle <> null) Or Self.fadeProcess > 0 then
					FadeOverToNextTitle()
				endif
			Else
				PlayMusic(MUSIC_MUSIC)
			Endif
		EndIf
	End Method
	
	Method FadeOverToNextTitle()		
		If (Self.fadeProcess = 0) Then
			Self.fadeProcess = 1
			Self.inactiveMusicChannel.SetVolume(0)			
			PlaySound(Self.nextMusicTitle, Self.inactiveMusicChannel)
			Self.nextMusicTitle = null
			Self.forceNextMusicTitle = false
			Self.fadeOutVolume = 1000
			Self.fadeInVolume = 0
		Endif
		
		If (Self.fadeProcess = 1) Then 'Das fade out des aktiven Channels
			Self.fadeOutVolume = Self.fadeOutVolume - 15
			Self.activeMusicChannel.SetVolume(float(Self.fadeOutVolume) / 1000 * Self.musicVolume)
			
			Self.fadeInVolume = Self.fadeInVolume + 15
			Self.inactiveMusicChannel.SetVolume(float(Self.fadeInVolume) / 1000 * Self.nextMusicTitleVolume)
		Endif
				
		if Self.fadeOutVolume <= 0 And Self.fadeInVolume >= 1000 then
			Self.fadeProcess = 0 'Prozess beendet
			Self.musicVolume = Self.nextMusicTitleVolume
			SwitchMusicChannels()
		endif									
	End Method
	
	Method SwitchMusicChannels()
		Local channelTemp:TChannel = Self.activeMusicChannel
		Self.activeMusicChannel = Self.inactiveMusicChannel
		Self.inactiveMusicChannel = channelTemp
		Self.inactiveMusicChannel.Stop()
	End Method

	Method PlayMusic(music:string)
		Self.nextMusicTitle = GetMusic(music)
		Self.forceNextMusicTitle = true
		Self.nextMusicTitleVolume = GetVolume(music)

		'Wenn der Musik-Channel noch nicht l�uft, dann jetzt starten
		if (not Self.activeMusicChannel.Playing()) then
			Self.musicVolume = Self.nextMusicTitleVolume
			Self.activeMusicChannel.SetVolume(Self.musicVolume)
			PlaySound(Self.nextMusicTitle, Self.activeMusicChannel)
			Self.forceNextMusicTitle = false
		endif		
	End Method

	Method PlaySFX(sfx:string, element:TElementPosition, options:TSfxOptions = null)
	
		If (options = null) Then options = Self.defaultSfxOptions	
		local currSfx:TSound = Self.GetSFX(sfx)
		local currChannel:TChannel = Self.GetSFXChannel(sfx)	
			
		local elementfx:TMovingElementSFX = TMovingElementSFX.Create(self, sfx, currSfx, currChannel, receiver, element, options)
		
		elementfx.Play()
		
		If element.IsMovable()
			If MapContains(movingElements, elementfx.GetID()) Then MapRemove (movingElements, elementfx.GetID()) 'Alte Eintr�ge entfernen		
			MapInsert(movingElements, elementfx.GetID(), elementfx) 'Neuer Eintrag hinzuf�gen
			
			local count:int = 0
			For Local element:TMovingElementSFX = EachIn MapValues(movingElements)
				count = count + 1
			Next		
		Endif
	End Method
	
	Method GetMusic:TSound (music:string)
		Local result:TSound
		
		Select music
			Case MUSIC_MUSIC
				Local nextTitleNumber:int = int(Rnd(1,5))				
				while(nextTitleNumber = Self.lastTitleNumber)
					nextTitleNumber = int(Rnd(1,5))
				wend											
				result = TSound(MapValueForKey(Self.soundFiles, MUSIC_MUSIC + nextTitleNumber))
				Self.lastTitleNumber = nextTitleNumber 
				print "Play music: " + MUSIC_MUSIC + " (" + nextTitleNumber + ")"
			Default
				result = TSound(MapValueForKey(Self.soundFiles, music))
				print "Play music: " + MUSIC_MUSIC
		EndSelect
		Return result
	End Method
	
	Method GetSFX:TSound (sfx:string)
		Return TSound(MapValueForKey(Self.soundFiles, sfx))
	End Method	
	
	Method GetVolume:float(music:string)
		Select music
			Case MUSIC_TITLE
				return 1
			Default
				return 0.2
		EndSelect	
	End Method
	
	Method GetSFXChannel:TChannel(sfx:string)
		Select sfx
			Case SFX_ELEVATOR_DING
				Return Self.sfxChannel_Elevator
			Case SFX_ELEVATOR_ENGINE
				Return Self.sfxChannel_Elevator				
		EndSelect
	End Method
End Type

Type TMovingElementSFX
	Field soundManager:TSoundManager
	Field sfxName:string
	Field sfx:TSound = null
	Field channel:TChannel = null
	Field element:TElementPosition = null
	Field options:TSfxOptions = null
	Field receiver:TElementPosition = null	
	
	Function Create:TMovingElementSFX(_soundManager:TSoundManager, _sfxName:string, _sfx:TSound, _channel:TChannel, _receiver:TElementPosition, _element:TElementPosition, _options:TSfxOptions )
		local result:TMovingElementSFX= new TMovingElementSFX
		result.soundManager = _soundManager
		result.sfxName = _sfxName
		result.sfx = _sfx
		result.channel = _channel
		result.element = _element
		result.options = _options
		result.receiver = _receiver
		Return result
	End Function
	
	Method GetID:string()
		Return element.GetID() + "_" + sfxName
	End Method
	
	Method Play()
		AdjustSettings()
		PlaySound(sfx, channel)		
	End Method
	
	Method AdjustSettings()
		local playerPoint:TPoint = receiver.GetCenter()
		local elementPoint:TPoint = element.GetCenter()
		local distance:int = CalculateDistanceOfPoints(playerPoint, elementPoint)
		
		'Lautst�rke ist Abg�ngig von der Entfernung zur Ger�uschquelle
		local distanceVolume:float = options.GetVolume(distance)
		channel.SetVolume(SoundManager.sfxVolume * 0.75 * distanceVolume) '0.75 ist ein fixer Wert die Lautst�rke der SFX reduzieren soll		
		
		'Liegt die Ger�uschequelle links, muss der Pegel in Richtung linker Lautsprecher gehen und umgekehrt
		If (elementPoint.z = 0) Then
			'170 Grenzwert = Erst aber dem Abstand von 170 (gef�hlt/gesch�tzt) h�rt man nur noch von einer Seite. 
			'Ergebnis sollte ungef�hr zwischen -1 (links) und +1 (rechts) liegen.
			channel.SetPan(float(elementPoint.x - playerPoint.x) / 170)			
			channel.SetDepth(0) 'Die Tiefe spielt keine Rolle, da elementPoint.z = 0
		Else						
			local xAxis:float = CalculateIntDistance(elementPoint.x, playerPoint.x)
			local zAxis:float = CalculateIntDistance(elementPoint.z, playerPoint.z)				
			local angle:float = ATan(zAxis / xAxis) 'Winkelfunktion: Welchen Winkel hat der H�rer zur Soundquelle. 90� = davor/dahiner    0� = gleiche Ebene	tan(alpha) = Gegenkathete / Ankathete			

			local rawPan:float = ((90 - angle) / 90)
			'Den r/l Effekt sollte noch etwas abgeschw�cht werden, wenn die Quelle nah ist (im Real passiert dies durch zur�ckgeworfenen Schall).
			local panCorrection:float = max(0, min(1, xAxis / 170))
			local correctPan:float = rawPan * panCorrection 

			
			'0� => Aus einer Richtung  /  90� => aus beiden Richtungen
			If (elementPoint.x < playerPoint.x) Then 'von links
				channel.SetPan(-correctPan)
				'print "Pan:" + (-correctPan) + " - angle: " + angle + " (" + xAxis + "/" + zAxis + ")    # " + rawPan + " / " + panCorrection
			Elseif (elementPoint.x > playerPoint.x) Then 'von rechts
				channel.SetPan(correctPan)
				'print "Pan:" + correctPan + " - angle: " + angle + " (" + xAxis + "/" + zAxis + ")    # " + rawPan + " / " + panCorrection
			Else
				channel.SetPan(0)
			Endif
			
			If elementPoint.z < 0 Then 'Hintergrund
				channel.SetDepth(-(angle / 90)) 'Minuswert = Hintergrund / Pluswert = Vordergrund
				'print "Depth:" + (-(angle / 90)) + " - angle: " + angle + " (" + xAxis + "/" + zAxis + ")"
			ElseIf elementPoint.z > 0 Then 'Vordergrund
				channel.SetDepth(angle / 90) 'Minuswert = Hintergrund / Pluswert = Vordergrund
				'print "Depth:" + (angle / 90) + " - angle: " + angle + " (" + xAxis + "/" + zAxis + ")"
			Endif
			'TODO: Offene Frage: H�ngt die Depth auch von der Y-Achse ab?
			'Beispiel: Etwas ist 20 m vom H�rer weg (auf der Z-Achse) im Hintergrund.
			'Ver�ndert sich die Depth auch, wenn sich die Ger�uschquelle (weiterhin 20 Meter auf der z-Achse) nach oben oder unten bewegt (also zus�tzlich zur Lautst�rke)? Ich glaube nicht.
		Endif					
	End Method
End Type

Type TSfxOptions
	Field nearbyDistanceRange:int = -1
	Field maxDistanceRange:int = 1000
	
	Field nearbyRangeVolume:float = 1
	Field midRangeVolume:float = 0.8
	Field minVolume:float = 0
	
	Function Create:TSfxOptions()
		Return new TSfxOptions 
	End Function	
	
	Method GetVolume:float(currentDistance:int)
		local result:float = midRangeVolume
		If (currentDistance <> -1) Then			
			If currentDistance > Self.maxDistanceRange Then 'zu weit weg
				result = Self.minVolume
			Elseif currentDistance < Self.nearbyDistanceRange Then 'sehr nah dran
				result = Self.nearbyRangeVolume
			Else 'irgendwo dazwischen
				result = midRangeVolume * (float(Self.maxDistanceRange) - float(currentDistance)) / float(Self.maxDistanceRange)
			Endif				
		Endif	
		
		Return result
	End Method
	
	Function GetElevatorOptions:TSfxOptions()
		local result:TSfxOptions = new TSfxOptions
		result.nearbyDistanceRange = 30
		result.maxDistanceRange = 500			
		result.nearbyRangeVolume = 1
		result.midRangeVolume = 0.5
		result.minVolume = 0.05
		Return result
	End Function
	
	Function GetMoveableElevatorOptions:TSfxOptions()
		local result:TSfxOptions = new TSfxOptions
		result.nearbyDistanceRange = 0
		result.maxDistanceRange = 500			
		result.nearbyRangeVolume = 0.5
		result.midRangeVolume = 0.5
		result.minVolume = 0.05
		Return result
	End Function
End Type


'Das ElementPositionzeug kann auch eventuell wo anders hin
Type TElementPosition 'Basisklasse f�r verschiedene Wrapper
	Method GetID:string() abstract
'	Method GetTopLeft:TPoint() abstract
	Method GetCenter:TPoint() abstract
	Method GetIsVisible:int() abstract		
	Method IsMovable:int() abstract
End Type


Function CalculateDistanceOfPoints:int(point1:TPoint, point2:TPoint)
	local distanceX:int = CalculateIntDistance(point1.x, point2.x)
	local distanceY:int = CalculateIntDistance(point1.y, point2.y)	
	Return Sqr(distanceX * distanceX + distanceY * distanceY) 'a� + b� = c�	
End function

Function CalculateIntDistance:int(value1:int, value2:int)
	If (value1 > value2) Then
		Return value1 - value2
	Else
		Return value2 - value1
	EndIf
End Function