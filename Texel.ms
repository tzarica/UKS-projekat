	fn GetResolution ResolutionString = 
	(
		local theResolution = case ResolutionString of
		(
			" 8192x8192": 8192
			" 4096x4096": 4096
			" 2048x2048": 2048
			" 1024x1024": 1024
			" 512x512": 512
			" 256x256": 256
			" 128x128": 128
		)
		return theResolution
	)
	
	fn GetMetersFromGU = 
	(
		local meters = case units.systemType of
		(
			#Inches: 0.0254
			#Feet: 0.3048
			#Miles: 1609.0
			#Millimeters: 0.001
			#Centimeters: 0.01
			#Meters: 1.0
			#Kilometers: 1000.0
		)
		return meters*units.SystemScale 
	) 
	
	format "GetMetersFromGU: %\n" GetMetersFromGU()

	
	clearListener()
		
	try(destroyDialog mainRoll)catch() -- if there is already dialog named mainRoll opened then script will destroy it and creates new one.
	
	fn ProcessSelection obj = 
	(		
		if obj != undefined then
		(
			unwrapMod = for m in obj.modifiers where classof m == Unwrap_UVW collect m

			if unwrapMod.count == 1 then
			(
				DisplayTexelDensity obj unwrapMod
				DisplayMapChannels obj unwrapMod
			)
			else if unwrapMod.count > 1 then
			(
				mainRoll.printFeed "Has mutliple Unwrap_UVW modifiers!!!"
				mainRoll.densityDisplay.text = ""
			)
			else
			(
				mainRoll.printFeed "Doesn't have Unwrap_UVW modifiers!"
				mainRoll.densityDisplay.text = ""
			)
		)
		else mainRoll.printFeed ("You must select something first!")
	)
	
	fn DisplayTexelDensity obj unwrapMod = 
	(
			texelDensity = GetTexelDensity obj unwrapMod[1]
-- 			
			mainRoll.densityDisplay.text =  (texelDensity/(GetMetersFromGU())) as string			
					
			mainRoll.printFeed ("Display Texel Density ::: Done!")
	)
	
	fn GetTexelDensity obj unwrap = 
	(
		if obj != undefined AND unwrap != undefined do
		(
			faces = unwrap.selectFacesByNode #{1..obj.numfaces} obj
			
			--Make an array of selected Faces
			if (faces = unwrap.getSelectedFaces()).count > 0 do
			(
				-- Get some information about the selection

				unwrap.getarea faces &mX &mY &mWidth &mHeight &mAreaUVW &mAreaGeom
				print mX
				print mY
				print mWidth
				print mHeight
				print mAreaUVW
				print mAreaGeom
				
				
				
				textureArea = GetResolution (mainRoll.dropdownResolution.selected)^2

				
				usedAreaPixels = mAreaUVW * textureArea

				
				texelDensity = sqrt (usedAreaPixels/mAreaGeom)
			
				format "Get Texel Density: %\n" texelDensity
				return texelDensity
			)
		)
	)
	
	fn SetTexelDensity obj =
	(
		if obj != undefined then
		(
			unwrapMod = for m in obj.modifiers where classof m == Unwrap_UVW collect m
			
			realSetDensity = mainRoll.densityInput.value * (GetMetersFromGU())	
			
			if realSetDensity >0 then
			(

				----it will rescale the cluster to equalize the texel density
				actionMan.executeAction 2077580866 "40207"

				texelDensityCluster = GetTexelDensity obj unwrapMod[1]

				--it will acknowledge the texel density of cluster so we can define the ratio
				--getting the ratio between single face and cluster
				theDefinedRatio=(realSetDensity/texelDensityCluster)
				unwrapMod[1].scaleSelectedCenter theDefinedRatio 0
			)
			else messagebox "Please set Texel Density correctly."
			--end of Normalization
			
			DisplayTexelDensity obj unwrapMod
		)
	)
	
	fn DisplayMapChannels obj unwrapMod =
	(
-- 		ChannelInfo.NameChannel obj 3 1 "UV1"
-- 		ChannelInfo.NameChannel obj 3 2 "UV2"
-- 		
-- 		channelName1 = getUserProp obj ("MapChannel:" + 1 as string)
-- 		channelName2 = getUserProp obj ("MapChannel:" + 2 as string)

-- 		if channelName1 != undefined do
-- 			mainRoll.uv1Name.text = channelName1
-- 		
-- 		if channelName2 != undefined do
-- 			mainRoll.uv2Name.text = channelName2
	)

	rollout mainRoll "Texel Editor"
	(
		local obj_ResolutionsArray = #(" 8192x8192", " 4096x4096", " 2048x2048", " 1024x1024", " 512x512", " 256x256", " 128x128")
		local currentSelection = undefined
		
		label cs "Current Selection" align:#center width:150 height:16	
		label selection_label "None" align:#center style_sunkenedge:true width:150 height:16	

		label resLabel "Map Size: " pos:[25,60] align:#center width:75 height:16	
		dropdownlist dropdownResolution pos:[75,60] align:#center items:obj_ResolutionsArray width:100 selection: 4 Tooltip: "Target map resolution"
			on dropdownResolution selected i do ProcessSelection currentSelection
 		
		button densityGet "Get Texel Density" pos:[25,92] width:125 height:16
			on densityGet pressed do ProcessSelection (currentSelection)

		label densityDisplay "" pos:[175, 92] style_sunkenedge:true width:100 height:16

		spinner densityInput range:[0,8192,1] pos:[175, 128] width:100 height:16 type:#float scale: 1 tooltip: "Texel density"
		button densitySet "Set Texel Density" pos:[25,128] width:125 height:16
			on densitySet pressed do SetTexelDensity (currentSelection)
				

			
		label feedbackText "" style_sunkenedge:true pos:[25, 250] width:250 height:32
		
		fn printFeed labelText = ( feedbackText.text = labelText )

		fn check_selection obj = 
		(
			if selection.count>0 do 
			(
				if selection.count<2 do 
					(
						selection_label.text  = " " + obj.name
						currentSelection = obj
						ProcessSelection obj
					)
					
				if selection.count>1 do 
					(
						selection_label.text  = " " + obj[1].name
						currentSelection = obj[1]
						ProcessSelection obj[1]
					)
			)
			
			if selection.count< 1 do
			(
				selection_label.text  = " None"
				currentSelection = null
				densityDisplay.text = ""
			)
		)
		
			
		on mainRoll close do callbacks.removescripts #selectionSetChanged id:#cb1
		on mainRoll open do callbacks.addScript #selectionSetChanged "mainRoll.check_selection $" id:#cb1
	)
		
	createDialog mainRoll 300 300 -- creates dialog named mainRoll, size is width:300 and height:300
	mainRoll.check_selection $ -- check selection after opening the Rollout


