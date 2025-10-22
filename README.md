Credit to the Oomer and Chiefster whos shaders I used as reference for how to work with Halo 4's functions, theChunkierBean for testing, and theHostileNegotiator and Amit for important help and feedback.

To install, simply download and drag-n-drop the "shaders" folder into your H4EK's "tags" folder.

By default, screen-space lights will not work with this shader due to them being handled in a later render pass. You can make them work by adding the files in "H4 Explicit Shaders - optional" to your
H4EK, but this will affect how some vanilla materials behave under those lights as they can't really take into account what material shader is being used. If you just want to make custom content and
aren't going to use vanilla content, this won't matter to you and you can use the explicit shaders without worry. If you are making modifications to vanilla content like the campaign, keep this in
mind when choosing whether or not to use them.


Some of the information below may be out-of-date and there are more regular shaders than shown here but I'm not gonna update this README file much more until the next big update, so DM me on Discord if 
you're trying to figure something out.

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

	-Make sure the textures for each material are the same resolution. If all of your albedo maps are 1024 except for one, that one texture won't import as part of the array.

	-For each texture in your material to be blended on the red channel, name each as the type of map followed by "_array0".
	 (e.g. Albedo_array0, Normal_array0, ORM_array0)

	-For each material afterwards use the same naming convention and add one to the number at the end.
	 (e.g. Albedo_array1 for albedo on the green channel)

	-Import your bitmaps folder. If it imported only one bitmap of each type without "_array" at the end, you've done it right.

	-Set the correct settings for your bitmap type through the usage overide specifically.
	 (refer to the usage override settings used for bitmaps imported via Foundry if you're unsure)

	-In the usage override, set "type" to array. Then save and close the bitmap.

	-Reimport the bitmaps folder through tool (Foundry will crash if you have the bitmap tags still open). These tags will now be ready to use in a blend material.
 	 Trying to open the bitmap tags again after this step will crash Foundry however, so make sure you get your import settings right the first time.

