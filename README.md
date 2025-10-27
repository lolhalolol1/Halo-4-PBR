#Halo 4 PBR
A set of shaders made for Halo 4 and Halo 2 Anniversary Multiplayer that allow you to use modern BRDFs for material rendering and more modern, standerdized workflows for authoring materials.
Credit to the Oomer and Chiefster whos shaders I used as reference for how to work with Halo 4's functions, theChunkierBean for testing, and theHostileNegotiator and Amit for important help and feedback.

##Installation
To install, simply download and drag-n-drop the "tags" folder for the toolset you are using into the folder into your editing kit's root folder.

By default, screen-space lights will not work with this shader due to them being handled in a later render pass. You can make them work by adding the files in "H4 Explicit Shaders - optional" to your
H4EK, but this will affect how some vanilla materials behave under those lights as they can't really take into account what material shader is being used. If you just want to make custom content and
aren't going to use vanilla content, this won't matter to you and you can use the explicit shaders without worry. If you are making modifications to vanilla content like the campaign, keep this in
mind when choosing whether or not to use them.

##How to Use
When working with a material in Bonobo/Foundation, at the top of the tag you can change the shader template.
The main PBR shader templates can be found in "shaders\material_shaders\materials_pbr". 
The older/outdated PBR shader templates can still be found in "shaders\material_shaders\materials_pbr" but I strongly recommend you use the newer ones as these will not recieve further updates.

Depending on the template you select, different features will be available and different textures can be used or will be required.
The most basic template usess the following textures:

  	-Albedo map
	
  	-Combo map (R = Ambient Occlusion, G = Roughness, B = Metallness, A = Height)
	
	-Normal map

For templates that include "cov", "em", and "coat" in the name, additional features will be useable and an additional combo map will be required with different channels being used depending on which features are included in the template.
The channels that are used for each feature are as follows:

  	-R: Clear-coat Rughness 	(for templates that allow for a clear-coat on materials, with the "coat" suffix)
  	-G: Clear-coat Mask			(for templates that allow for a clear-coat on materials, with the "coat" suffix)
	-B: Covenant Mask			(for templates that allow for irridecence on materials, with the "cov" or "covn" suffix)
	-A: Emissive Mask			(for templates that allow for emissive regions on materials, using the term "em")

Templates that have "covn" in the name wil also allow for an extra detail normal map that's masked in by the "Covenenant Mask". 
There are also templates that include support for detail textures ("det"), colour-change ("cc" and "cc_previs), and alpha clip ("clip")
I'll assume you're familiar enough with these to know what textures you'll need.

I'll likely create a better explanation what each of these features do specifically in the future alongside explanations of new features I will be adding, but this'll have to do for now. If you have questions, DM me on Discord.

##Terrain/Blended Materials
For 4-way blend materials you will need to create texture arrays to use for your Albedo, ORM, and Normal maps.
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

This is necessary to avoid the limit on textures in Halo 4. I know it's not a perfect solution but it's currently the best one I have. 3-way blend materials that use individual bitmaps per channel will be added eventually.
