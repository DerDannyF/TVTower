Type TPersonMinimal
	Field id:string
	Field firstName:string			= ""
	Field lastName:string			= ""
	Field features:Int				= 0 'Immer 0 bei TPersonMinimal. Bei TPerson: 0=Unbekannt/Minimal-Datensatz	1=C-Promi (buchbar)	2=B-Promi (buchbar, Trend) 3=A-Promi (buchbar, Trend, in den News)

	Method GetFullName:String()
		Return firstName + " " + lastName
	End Method
End Type


Type TPerson Extends TPersonMinimal
	Field firstName:string			= ""
	Field lastName:string			= ""
	Field nickName:string			= ""
	Field gender:Int				= 0	'0=Unbekannt 1=Mann 2=Frau
	
	Field dayOfBrith:Int			= 0
	Field debut:Int					= 0	
	Field dayOfDeath:Int			= 0		
	Field country:String			= 0

	Field functions:Int				= 0 '0=unbekannt, +1=actor, +2=director, +4=host, +8=reporter, +16=musician, +32=intellectual
	Field topGenre1:Int				= -1
	Field topGenre2:Int				= -1
	
	Field fame:Int					= 0 '0 - 100	Kinokasse +++					Wie ber�hmt ist die Person?
	Field scandalizing:Int			= 0 '0 - 100	Besonders Interessant f�r Shows und Sonderevents und Ausl�ser f�r News
	Field priceFactor:Int			= 0 '0 - 100	F�r die Manipulation des Preises. Manche sind teurer/g�nstiger als ihre Leistung erwarten w�rde.

	Field skill:Int					= 0 '0 - 100	Kinokasse +		Kritik +++		Bonus bei manchen Genre (wie Drama)! F�r Regisseur, Musiker und Intellektueller: Wie gut kann er sein Handwerk		
	Field power:Int					= 0 '0 - 100	Kinokasse +		Tempo +++		Bonus bei manchen Genre (wie Action)
	Field humor:Int					= 0 '0 - 100	Kinokasse +		Tempo +++		Bonus bei manchen Genre (wie Kom�die)
	Field charisma:Int				= 0 '0 - 100	Kinokasse +		Kritik ++		Bonus bei manchen Genre (wie Liebe, Drama, Kom�die)
	Field appearance:Int			= 0 '0 - 100	Kinokasse ++ 	Tempo +			Bonus bei manchen Genre (wie Erotik, Liebe, Action)	
	
	Method GetActorBaseFee:Int() 'Das Grundhonorar als Schauspieler
		'TODO: �berarbeiten
		local sum:float = 50 + power + humor + charisma + appearance + skill * 2 '(50 bis 650)
		Local factor:Float = (fame*0.8 + scandalizing*0.2)/50
		
		Return 3000 + Floor(Int(sum * factor * 200 * priceFactor / 50)/100)*100
	End Method
	
	Method GetGuestFee:Int() 'Kosten als Studiogast
		'TODO: �berarbeiten
		local sum:float = 50 + fame*2 + scandalizing*0.5 + humor*0.3 + charisma*0.3 + appearance*0.3 + skill
		Return 100 + Floor(Int(sum * priceFactor / 50)/100)*100
	End Method
End Type