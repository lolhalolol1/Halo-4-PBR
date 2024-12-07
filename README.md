Credit to the Oomer and Chiefster whos shaders I used as reference for how to work with Halo 4's functions, theChunkierBean for testing, and theHostileNegotiator and Amit for important help and feedback.

To install, simply download and drag-n-drop the "shaders" folder into your H4EK's "tags" folder.


Input maps are as follows...

Metalness-Roughness workflow:

  	-Albedo map
	
  	-ORM map (R = Ambient Occlusion, G = Roughness, B = Metallness, A = Height)
	
	-Normal map

	-Detail normal map


Spec-Gloss workflow:

	-Albedo Map

	-Specular Map (RGB = f0, A = glossiness)

	-Occlusion Map (RGB = Ambient Occlusion, A = height)

	-Normal map

	-Detail normal map



Also optionally...

  	-Emissive map




For 4-way blend materials:

You will need to create texture arrays to use for your Albedo, ORM, and Normal maps.
To do this:
	-For each texture in your material to be blended on the red channel, name each as the type of map followed by "_array0".
	 (e.g. Albedo_array0, Normal_array0, ORM_array0)

	-For each material afterwards use the same naming convention and add one to the number at the end.
	 (e.g. Albedo_array1 for albedo on the green channel)

	-Import your bitmaps folder. If it imported only one bitmap of each type without "_array" at the end, you've done it right.

	-Set the correct settings for your bitmap type (refer to the usage override settings used for Foundry imports if you're unsure)

	-In the usage override, set "type" to array. Then save and close the bitmap.

	-Reimport the bitmaps folder (Foundry will crash if you have the bitmap tags still open). These tags will now be ready to use in a blend material.
 	 (trying to open the bitmap tags themselves again will crash Foundry however, so keep that in mind)

If you want to scale the material maps in a blended material and use parallax at the same time, use the "parallax tile" option for now (parallax does not scale correctly otherwise for now).

