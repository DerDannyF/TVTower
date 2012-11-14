Type TElevator
	'Room_Elevator_Compute => dort wird der Fahrstuhl berechnet

	Field Building :TBuilding				= null		'Das Geb�ude
	Field FloorRouteList:TList				= CreateList() 'Die Liste mit allen Fahrstuhlanfragen und Sendekommandos in der Reihenfolge in der sie gestellt wurden
	Field TemporaryRouteList:TList			= null		'Die tempor�re RouteList. Sie ist so lange aktuell, bis sich etwas an FloorRouteList �ndert, dann wird TemporaryRouteList auf null gesetzt
	Field CurrentFloor:Int					= 0			'Aktuelles Stockwerk
	Field TargetFloor:Int					= 0			'Hier f�hrt der Fahrstuhl hin
	
	Field Pos:TPoint						= TPoint.Create(131+230,115) 	'Aktuelle Position - difference to x/y of building
	
	Field PlanTime:Int						= 4000 'TODOX muss gekl�rt werden was das ist
	
	Field DoorStatus:Int 					= 0    '0 = closed, 1 = open, 2 = opening, 3 = closing
	Field ElevatorStatus:Int				= 0			'0 = warte auf n�chsten Auftrag, 1 = T�ren schlie�en, 2 = Fahren, 3 = T�ren �ffnen, 4 = entladen/beladen, 5 = warte auf Nutzereingabe
		
	'Field WaitAtFloorTime:Int				= 2000 		'Wie lange (Millisekunden) werden die T�ren offen gelassen		
	Field WaitAtFloorTime:Int				= 650 		'Wie lange (Millisekunden) werden die T�ren offen gelassen
	Field WaitAtFloorTimer:Int				= 0			'Der Fahrstuhl wartet so lange, bis diese Zeit erreicht ist (in Millisekunden - basierend auf MilliSecs() + waitAtFloorTime)
	Field BlockedByFigureUsingPlan:Int		= -1		'player using plan / Spieler-ID oder -1
	
	Field Passengers:TList					= CreateList()	'Alle aktuellen Passagiere als TFigures
	
	Field Direction:Int						= 1			'Aktuelle/letzte Bewegungsrichtung: -1 = nach unten; +1 = nach oben; 0 = gibt es nicht
	
	Field Speed:Float 			= 120  								'pixels per second ;D
	
	Field ReadyForBoarding:int				= false		'w�hrend der ElevatorStatus 4, 5 und 0 m�glich.
	
	Field TopTuringPointForSort:int = -1
	Field BottomTuringPointForSort:int = -1
	
	'Grafikelemente
	Field SpriteDoor:TAnimSprites
	Field SpriteInner:TGW_Sprites
	
	Function Create:TElevator(building:TBuilding)
		Local obj:TElevator = New TElevator
		obj.spriteDoor = new TAnimSprites.Create(Assets.GetSprite("gfx_building_Fahrstuhl_oeffnend"), 8, 150)
		obj.spriteDoor.insertAnimation("default", TAnimation.Create([ [0,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("closed", TAnimation.Create([ [0,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("open", TAnimation.Create([ [7,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("opendoor", TAnimation.Create([ [0,70],[1,70],[2,70],[3,70],[4,70],[5,70],[6,70],[7,70] ], 0, 1) )
		obj.spriteDoor.insertAnimation("closedoor", TAnimation.Create([ [7,70],[6,70],[5,70],[4,70],[3,70],[2,70],[1,70],[0,70] ], 0, 1) )
		obj.spriteInner	= Assets.GetSprite("gfx_building_Fahrstuhl_Innen")  'gfx_building_elevator_inner
		obj.Building = building
		obj.Pos.SetY(building.GetFloorY(obj.CurrentFloor) - obj.spriteInner.h)	
		
		obj.spriteDoor.setCurrentAnimation("open")
		obj.doorStatus = 1 'open			
		Return obj
	End Function
	
	Method Save()
		'TODO
	End Method	
	
	Method Load(loadfile:TStream)
		'TODO
	End Method
	
	Method GetDoorWidth:int()
		Return spriteDoor.sprite.framew
	End Method
	
	Method GetDoorCenterX:int()
		Return Building.pos.x + Pos.x + spriteDoor.sprite.framew/2
	End Method
	
	Method IsFigureInFrontOfDoor:Int(figure:TFigures)
		Return (GetDoorCenterX() = figure.GetCenterX())
	End Method	

	Method IsFigureInElevator:Byte(figure:TFigures)
		'If IsFigureInFrontOfDoor(figure)
			Return passengers.Contains(figure)
		'Else
		'	Return False
		'EndIf		
	End Method
		
	Function CalcDirection:Int(fromFloor:int, toFloor:int)
		if (fromFloor < toFloor)
			Return 1
		else
			Return -1
		Endif		
	End Function
	
	Method IsAllowedToEnterToElevator:int(figure:TFigures, myTargetFloor:int=-1)		
		'Man darf auch einsteigen wenn man eigentlich in ne andere Richtung wollte... ist der Parameter aber dabei, dann wird gepr�ft
		Print "IsAllowedToEnterToElevator: " + myTargetFloor + "    (" + Direction + " = " + CalcDirection(CurrentFloor, myTargetFloor) +","+ CurrentFloor + " = " + TopTuringPointForSort + " And " + Direction + " = 1," + CurrentFloor + " = " + BottomTuringPointForSort + " And " + Direction + "= -1)      [" + False + "," + True + "]..."
		print "Direction: " + Direction + "; CurrentFloor: " + CurrentFloor + "; myTargetFloor: " + myTargetFloor + "; TopTuringPointForSort: " + TopTuringPointForSort + "; BottomTuringPointForSort: " + BottomTuringPointForSort 
		
		If myTargetFloor = -1 Then Return True		
		print "Direction2"
		If (Direction = CalcDirection(CurrentFloor, myTargetFloor) Or (CurrentFloor = TopTuringPointForSort And Direction = 1) Or (CurrentFloor = BottomTuringPointForSort And Direction = -1)) Then Return true
		
	End Method
	
	Method EnterTheElevator:int(figure:TFigures, myTargetFloor:int=-1) 'bzw. einsteigen				

		If IsAllowedToEnterToElevator(figure, myTargetFloor)
			print "Passagier kommt rein: " + figure.name + " -> " + myTargetFloor + " R:" + CalcDirection(CurrentFloor, myTargetFloor)
		Else
			print "Passagier abgelehnt: " + figure.name + " -> " + myTargetFloor + " R:" + CalcDirection(CurrentFloor, myTargetFloor)
			Return false
		Endif
	
		If Not passengers.Contains(figure)
			passengers.AddLast(figure)	
			local currentRoute:TFloorRoute = GetRouteByPassenger(figure, 1)
			if (currentRoute <> null)
				FloorRouteList.remove(currentRoute)
				If TemporaryRouteList <> null Then TemporaryRouteList.remove(currentRoute)
				'TemporaryRouteList = null
			Endif
			Return true
		Endif
		Return false
	End Method
	
	Method LeaveTheElevator(figure:TFigures) 'aussteigen
		local route:TFloorRoute = GetRouteByPassenger(figure, 0)
		if (route <> null)						
			FloorRouteList.remove(route)
			If TemporaryRouteList <> null Then TemporaryRouteList.remove(route)
			'TemporaryRouteList = null
		
			Passengers.remove(figure)			
		Endif
	End Method
	
	Method CallElevator(figure:TFigures)
		AddFloorRoute(figure.GetFloor(), 1, figure, not figure.IsGameLeader())
	End Method
	
	Method SendElevator(targetFloor:int, figure:TFigures)
		AddFloorRoute(targetFloor, 0, figure, not figure.IsGameLeader())		
	End Method		
	
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigures, fromNetwork:Int = False)
		If Not ElevatorCallIsDuplicate(floornumber, who) Then 'Pr�fe auf Duplikate
			FloorRouteList.AddLast(TFloorRoute.Create(self, floornumber, call, who))
			TemporaryRouteList = null 'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
			'TODOX Netzwerk
		EndIf		
	End Method
	
	Method ElevatorCallIsDuplicate:Int(floornumber:Int, who:TFigures)
		For Local DupeRoute:TFloorRoute = EachIn FloorRouteList
			If DupeRoute.who.id = who.id And DupeRoute.floornumber = floornumber Then Return True
		Next
		Return False
	End Method
	
	Method SetDoorOpen()
		print "SetDoorOpen"
		'TODOX: Kann eigentlich raus... beim letzten Nutzer ersetzen
		Self.SpriteDoor.setCurrentAnimation("open")
		Self.DoorStatus = 1
	End Method
	rem
	Method Deboarding() 'Aussteigen		
		local passengersTemp:TList = Passengers.Copy()
		For Local passenger:TFigures = EachIn passengersTemp
			local route:TFloorRoute = GetRouteByPassenger(passenger, false)
			If route.floornumber = CurrentFloor 'Bitte hier aussteigen
				passenger.inElevator = False
				Passengers.remove(passenger)
				FloorRouteList.remove(route)
				If TemporaryRouteList <> null Then TemporaryRouteList.remove(route)
			Endif		
		Next	
	End Method
	endrem
	Method GetRouteByPassenger:TFloorRoute(passenger:TFigures, isCallRoute:int)
		For Local route:TFloorRoute = EachIn FloorRouteList
			If route.who = passenger And route.call = isCallRoute Then Return route
		Next
		Return null
	End Method
	
	Method OpenDoor()
		print CurrentFloor + " OpenDoor"
		Self.spriteDoor.setCurrentAnimation("opendoor", True)
		DoorStatus = 2 'wird geoeffnet
		If Game.networkgame Then Self.Network_SendSynchronize()
	End Method	
	
	Method CloseDoor()
		print CurrentFloor + " CloseDoor"
		Self.spriteDoor.setCurrentAnimation("closedoor", True)
		DoorStatus = 3 'closing
		If Game.networkgame Then Self.Network_SendSynchronize()
	End Method	
	
	Function DefaultRouteSort:Int( o1:Object, o2:Object )
		Return TFloorRoute(o1).CalcSortNumber() - TFloorRoute(o2).CalcSortNumber()
	End Function				
	
	Function PlayerPreferenceRouteSort:Int( o1:Object, o2:Object )
		local route1:TFloorRoute = TFloorRoute(o1)
		local route2:TFloorRoute = TFloorRoute(o2)
'		print "PlayerPreferenceRouteSort1: " + route1.who.id + " - " + route2.who.id
		If route1.who.IsActivePlayer()			
			If route2.who.IsActivePlayer()
'				print "PlayerPreferenceRouteSort2: " + (GetRouteIndexOfFigure(route1.who) - GetRouteIndexOfFigure(route2.who))
				Return GetRouteIndexOfFigure(route1.who) - GetRouteIndexOfFigure(route2.who)
			Else
'				print "PlayerPreferenceRouteSort3: -1"
				Return -1
			Endif			
		Else
			If route2.who.IsActivePlayer()
				'print "PlayerPreferenceRouteSort4: 1"
				Return 1
			Endif
		Endif
	
'		print "PlayerPreferenceRouteSort5: " + (route1.CalcSortNumber() - route2.CalcSortNumber())
		Return route1.CalcSortNumber() - route2.CalcSortNumber()
	End Function	
	
	Function GetRouteIndexOfFigure:int(figure:TFigures)
		local index:int=0
		For Local route:TFloorRoute = EachIn Building.Elevator.FloorRouteList
			If route.who = figure Then Return index
		Next
		Return -1
	End Function	
	
	Method CalculateNextTarget:int()
		if TemporaryRouteList = null		
			TopTuringPointForSort= -1;
			BottomTuringPointForSort= 20;

			For Local route:TFloorRoute = EachIn FloorRouteList
				If route.floornumber < BottomTuringPointForSort Then BottomTuringPointForSort = route.floornumber
				If route.floornumber > TopTuringPointForSort Then TopTuringPointForSort = route.floornumber
				route.sortNumber = -1
			Next	
			print "..........................................................................A: " + Direction 
			If ElevatorStatus <> 2
				Direction = GetPlayerPreferenceDirection()			
				print "..........................................................................B: " + Direction 
				
				For Local route:TFloorRoute = EachIn FloorRouteList
					route.sortNumber = -1
				Next			
			Endif
			
			If CurrentFloor >= TopTuringPointForSort Then Direction = -1
			If CurrentFloor <= BottomTuringPointForSort Then Direction = 1			
		
			local tempList:TList = FloorRouteList.Copy()												
			SortList(tempList, True, DefaultRouteSort)
			TemporaryRouteList = tempList
			
			Print ">>>>>>>>>>>>>>>"
			print "Direction: " + Direction
			print "CurrentFloor: " + CurrentFloor + "     ( " + BottomTuringPointForSort + "->" + TopTuringPointForSort + ")"
			print "==="
			For Local figure:TFigures = EachIn Passengers
				print figure.name
			Next
			print "==="			
			For Local route:TFloorRoute = EachIn TemporaryRouteList 
				print route.ToStringX("")
			Next
			Print "<<<<<<<<<<<<<<<"
		Endif
		
		Local nextTarget:TFloorRoute = TFloorRoute(TemporaryRouteList.First())
		If nextTarget <> null
			'If (nextTarget.floornumber < TargetFloor And Direction = 1) Or (nextTarget.floornumber > TargetFloor And Direction = -1) 'Ein Richtungswechsel... bitte neu berechnen			
			Return nextTarget.floornumber
		Else
			Return TargetFloor
		Endif
	End Method
	
	Method GetPlayerPreferenceDirection:int()
		local tempList:TList = FloorRouteList.Copy()		
		If Not tempList.IsEmpty()	
			SortList(tempList, True, PlayerPreferenceRouteSort)					
			local currRoute:TFloorRoute = TFloorRoute(tempList.First())
			if currRoute <> null
				If currRoute.who.IsActivePlayer()
					local target:int = currRoute.floornumber
					
					If CurrentFloor = target					
						Return Direction
					ElseIf CurrentFloor < target
						Return 1
					Else
						Return -1
					Endif
				Endif
			Endif
		Endif	
		Return Direction
	End Method
	
	Method RemoveIgnoredRoutes()
		Local tempList:TList = FloorRouteList.Copy()
		For Local route:TFloorRoute = EachIn tempList
			If route.floornumber = CurrentFloor And route.call = 1
				If passengers.Contains(route.who)					
					throw "Fehler im System: Person ist drin, aber der Call-Auftrag wurde nicht entfernt " + route.who.name
					passengers.remove(route.who)
				Else
					print "Entferne nicht wahrgenommene Call-Route von: " + route.who.name
					FloorRouteList.remove(route)
					If TemporaryRouteList <> null Then TemporaryRouteList.remove(route)				
				Endif															
			Endif
		Next		
	End Method
	
	Method Update(deltaTime:Float=1.0)					
		'TODOX: Pr�fen ob das irgendeinen Sinn macht!
		'the -1 is used for displace the object one pixel higher, so it has to reach the first pixel of the floor
		'until the function returns the new one, instead of positioning it directly on the floorground
		If Abs(Building.GetFloorY(Building.GetFloor(Building.pos.y + Pos.y + spriteInner.h - 1)) - (Pos.y + spriteInner.h)) <= 1
			CurrentFloor = Building.GetFloor(Building.pos.y + Pos.y + spriteInner.h - 1)
		EndIf
	
'		Print "ElevatorStatus = " + ElevatorStatus + "        " + CurrentFloor  + " -> " + TargetFloor 
	
		If ElevatorStatus = 0 '0 = warte auf n�chsten Auftrag	
			TargetFloor = CalculateNextTarget() 'N�chstes Ziel in der Route
			If CurrentFloor <> TargetFloor 'neues Ziel gefunden
				ReadyForBoarding = false
				ElevatorStatus = 1 'T�ren schlie�en
			Endif
		Endif	

		If ElevatorStatus = 1 '1 = T�ren schlie�en		
			'Wenn die Wartezeit vorbei ist, dann T�ren schlie�en
			If doorStatus <> 0 And doorStatus <> 3 And waitAtFloorTimer <= MilliSecs() Then CloseDoor()
			
			'T�ranimation f�r das Schlie�en fortsetzen
			If spriteDoor.getCurrentAnimationName() = "closedoor"
				If spriteDoor.getCurrentAnimation().isFinished()					
					spriteDoor.setCurrentAnimation("closed")
					doorStatus = 0 'closed
					ElevatorStatus = 2 '2 = Fahren
				EndIf
			EndIf									
		Endif
		
		If ElevatorStatus = 2 '2 = Fahren		
			TargetFloor = CalculateNextTarget() 'Nochmal pr�fen ob es ein neueres Ziel gibt.
			
			if CurrentFloor = TargetFloor 'Ist der Fahrstuhl da/angekommen, aber die T�ren sind noch geschlossen? Dann �ffnen!
				ElevatorStatus = 3 'T�ren �ffnen					
			Else
				If (CurrentFloor < TargetFloor) Then Direction = 1 Else Direction = -1
											
				'Fahren - Position �ndern
				If Direction = 1
					Pos.y	= Max(Pos.y - deltaTime * Speed, Building.GetFloorY(TargetFloor) - spriteInner.h) 'hoch fahren
				Else
					Pos.y	= Min(Pos.y + deltaTime * Speed, Building.GetFloorY(TargetFloor) - spriteInner.h) 'runter fahren	
				EndIf

				'Begrenzungen: Nicht oben oder unten rausfahren ;)
				If Pos.y + spriteInner.h < Building.GetFloorY(13) Then Pos.y = Building.GetFloorY(13) - spriteInner.h
				If Pos.y + spriteInner.h > Building.GetFloorY( 0) Then Pos.y = Building.GetFloorY(0) - spriteInner.h		
				
				'Die Figuren im Fahrstuhl mit der Kabine mitbewegen
				For Local Figure:TFigures = EachIn Passengers
					Figure.rect.position.setY ( Building.Elevator.Pos.y + spriteInner.h)
				Next					
			EndIf						
		Endif		
		
		If ElevatorStatus = 3 '3 = T�ren �ffnen
			If doorStatus = 0
				OpenDoor()
				waitAtFloorTimer = MilliSecs() + waitAtFloorTime 'Es wird bestimmt wie lange die T�ren mindestens offen bleiben.
			Endif
		
			'T�ranimationen f�r das �ffnen fortsetzen... aber auch Passagiere ausladen, wenn es fertig ist
			If spriteDoor.getCurrentAnimationName() = "opendoor"
				If spriteDoor.getCurrentAnimation().isFinished()
					ElevatorStatus = 4 'entladen					
					print "door open"
					spriteDoor.setCurrentAnimation("open")
					doorStatus = 1 'open
				EndIf
			EndIf		
		Endif
		
		If ElevatorStatus = 4 '4 = entladen		
			If ReadyForBoarding = false
				print "aussteigen / einsteigen"
				'Deboarding() 'Jetzt aussteigen
				ReadyForBoarding = true
			Else 'ist im Else-Zweig damit die Update-Loop nochmal zu den Figuren wechseln kann um ein-/auszusteigen
				'Wenn die Wartezeit um ist, dann nach nem neuen Ziel suchen
				If waitAtFloorTimer <= MilliSecs() Then				
					print "Entferne nicht wahrgenommene routen"
					RemoveIgnoredRoutes()	
					ElevatorStatus = 0
					TemporaryRouteList = null
				endif			
			Endif
		Endif
		
		If ElevatorStatus = 1 or ElevatorStatus = 3 Then spriteDoor.Update(deltaTime) 'T�re animieren
		
		'Tooltips aktualisieren
		'TODOX: Wirklich notwendig?
		TRooms.UpdateDoorToolTips(deltaTime)
	End Method
	
	
	
	
	
			
	Method Draw() 'needs to be restructured (some test-lines within)
		SetBlend MASKBLEND
		'TODOX: Warum werden hier die anderen T�ren gezeichnet? Vielleicht wieder rein machen
		TRooms.DrawDoors() 'draw overlay -open doors etc.   

		'Die fehlende T�r zeichnen... also da wo der Fahrstuhl ist
		spriteDoor.Draw(Building.pos.x + pos.x, Building.pos.y + Building.GetFloorY(CurrentFloor) - 50)
		
		'TODOX: Braucht man das?
		'REM
		For Local i:Int = 0 To 13
			Local locy:Int = Building.pos.y + Building.GetFloorY(i) - Self.spriteDoor.sprite.h - 8
			If locy < 410 And locy > -50
				SetColor 200,0,0
				DrawRect(Building.pos.x+Pos.x-4 + 10 + (CurrentFloor)*2, locy + 3, 2,2)
				SetColor 255,255,255
			EndIf
		Next
		'ENDREM

		'TODOX: Muss wohl �berarbeitet werden, da sich ja auch die Routen �ndern
		'Fahrstuhlanzeige �ber den T�ren
		For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
			Local locy:Int = Building.pos.y + Building.GetFloorY(floorroute.floornumber) - spriteInner.h + 23
			'elevator is called to this floor					'elevator will stop there (destination)
			If	 floorroute.call Then SetColor 200,220,20 	Else SetColor 100,220,20
			DrawRect(Building.pos.x + Pos.x + 44, locy, 3,3)
			SetColor 255,255,255
		Next

		SetBlend ALPHABLEND
	End Method
	
	Method DrawFloorDoors()		
		'Innenraum zeichen (BG)     =>   elevatorBG without image -> black
		SetColor 0,0,0
		DrawRect(Building.pos.x + 360, Max(Building.pos.y, 10) , 44, 373)
		SetColor 255, 255, 255		
		spriteInner.Draw(Building.pos.x + Pos.x, Building.pos.y + Pos.y + 3.0)
		
		'Zeichne Figuren
		If Not passengers.IsEmpty() Then
			For Local passenger:TFigures = EachIn passengers
				passenger.Draw()
				passenger.alreadydrawn = 1
			Next				
		Endif

		'Zeichne T�ren in allen Stockwerken (au�er im aktuellen)
		For Local i:Int = 0 To 13
			Local locy:Int = Building.pos.y + Building.GetFloorY(i) - Self.spriteDoor.sprite.h
			If locy < 410 And locy > - 50 And i <> CurrentFloor Then
				Self.spriteDoor.Draw(Building.pos.x + Pos.x, locy, "closed")
			Endif
		Next
	End Method	
	
	Method Network_SendRouteChange(floornumber:Int, call:Int=0, who:Int, First:Int=False)
		'TODOX
	End Method

	Method Network_ReceiveRouteChange( obj:TNetworkObject )
		'TODOX
	End Method

	Method Network_SendSynchronize()
		'TODOX
	End Method

	Method Network_ReceiveSynchronize( obj:TNetworkObject )
		'TODOX
	End Method		
	
End Type

'an elevator, contains rules how to draw and functions when to move
Type TFloorRoute
	Field elevator:TElevator
	Field floornumber:Int
	Field call:Int
	Field who:TFigures
	
	Field sortNumber:Int = -1
	
	Method Save()
	End Method

	Function Load:TFloorRoute(loadfile:TStream)
	End Function
	
	Function Create:TFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigures=null)
		Local floorRoute:TFloorRoute = New TFloorRoute
		floorRoute.elevator = elevator
		floorRoute.floornumber = floornumber
		floorRoute.call = call
		floorRoute.who = who		
		Return floorRoute
	End Function

	Method IntendedFollowingTarget:int()
		Return who.getFloor(who.target)
	End Method

	Method IntendedDirection:int()
		If call = 1
			If floornumber < IntendedFollowingTarget() Then Return 1 Else Return -1			
		Endif
		Return 0
	End Method
	
	Method IsAcceptableForPath:int(fromFloor:int, toFloor:int)
		local direction:int = GetDirectionOf(fromFloor, toFloor)
		
		If direction = 1 'nach oben
			If Not (floornumber >= fromFloor And floornumber <= toFloor) Then Return False
		Else
			If Not (floornumber <= fromFloor And floornumber >= toFloor) Then Return False
		Endif
		
		If call And direction <> IntendedDirection() Then Return False 'Ist die geplante Fahrtrichtung korrekt?
		
		Return True			
	End Method
	
	Method GetDirectionOf:int(fromFloor:int, toFloor:int)
		If fromFloor = toFloor Then Return 0
		If fromFloor < toFloor Then Return 1 Else Return -1
	End Method
		
	Method GetDistance:int( value1:int, value2:int)
		If value1 = value2
			Return 0
		Elseif value1 > value2
			Return value1 - value2
		Else
			Return value2 - value1
		Endif
	End Method
	
	Method CalcSortNumberForPath:int(fromFloor:int, toFloor:int, turningPointPenalty:int, notInPathPenalty:int)
		If IsAcceptableForPath(fromFloor, toFloor)
			Return GetDistance( fromFloor, floornumber ) * 100
		Elseif floornumber = toFloor 'Stehe am Wendepunkt des Fahrstuhls und passe sonst in keine Kategorie
			Return turningPointPenalty + GetDistance( fromFloor, floornumber ) * 100
		Else
			Return notInPathPenalty
		Endif
	End Method	
	
	Method CalcSortNumber:int()
		If sortNumber = -1	
			local currentPathTarget:int = 0, returnPathTarget:int = 0
			sortNumber = 0
			
			If elevator.Direction = 1
				currentPathTarget = elevator.TopTuringPointForSort
				returnPathTarget = elevator.BottomTuringPointForSort
			else
				currentPathTarget = elevator.BottomTuringPointForSort
				returnPathTarget = elevator.TopTuringPointForSort	
			endif
			
			'Hinweg
			sortNumber = sortNumber + CalcSortNumberForPath( elevator.CurrentFloor, currentPathTarget, 10000, 20000)
			If ( sortNumber >= 20000 ) 'nur auf dem R�ckweg zu bekommen
				sortNumber = sortNumber + CalcSortNumberForPath( currentPathTarget, returnPathTarget , 30000, 40000 )
				If ( sortNumber >= 60000 ) 'Hat zu sp�t gecalled f�r die Fahrt in diese Richtung. Liegt hinter der Fahrtrichtung
					sortNumber = sortNumber + GetDistance( returnPathTarget , elevator.CurrentFloor ) * 100
				Endif
			Endif
			
			'Zur konstanteren Sortierung... kann man eventuell auch weglassen
			sortNumber = sortNumber + GetDistance( floornumber, IntendedFollowingTarget() );					
		Endif
		Return sortNumber
	End Method

	'Method Compare:Int(otherObject:Object)	
	'	If otherObject = null Then Return 1
	'	Return CalcSortNumber() - TFloorRoute(otherObject).CalcSortNumber();
	'End Method	
	
	Method ToStringX:string(prefix:string)
		If call = 1
			Return prefix + self.ToString() + " C   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Else
			Return prefix + self.ToString() + " S   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Endif		
	End Method		
End Type
