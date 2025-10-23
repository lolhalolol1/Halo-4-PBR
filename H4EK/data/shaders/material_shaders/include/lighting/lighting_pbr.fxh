#if !defined(__LIGHTING_FXH)
#define __LIGHTING_FXH

#include "lighting/vmf.fxh"
#include "lighting/floating_shadow.fxh"
#include "lighting/shadows.fxh"
#include "lighting/lighting_models_pbr.fxh"


#if defined(cgfx)

#include "parameters/user_parameters.fxh"

#define DECLARE_LIGHT_DIRECTION(shader_name, ui_name, ui_group) \
	NEXT_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "Direction"; string Object = "Light"; string Space = "World"; bool DefaultForSwatchRendering = true; >
#define DECLARE_LIGHT_COLOR(shader_name, ui_name, ui_group) \
	NEXT_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = false; bool DefaultForSwatchRendering = true; >
#define DECLARE_LIGHT_INTESITY(shader_name, ui_name, ui_group, ui_min, ui_max) \
	NEXT_FLOAT1(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float"; float Minimum = ui_min; float Maximum = ui_max; bool DefaultForSwatchRendering = true; >

// light1
DECLARE_LIGHT_DIRECTION(LightDirection0, "Light Direction 0", "Lights") 		= float3(0.58682907954047003f, -0.61724527085219505f, -0.52406097642954197f);
#include "used_float3.fxh"
DECLARE_LIGHT_COLOR(LightColor0, "Light Color 0", "Lights")    					= float3(0, 0, 0);
#include "used_float3.fxh"
DECLARE_LIGHT_INTESITY(LightIntensity0, "Light Intensity 0", "Lights", 0, 100)	= float(0);
#include "used_float.fxh"

// light2
DECLARE_LIGHT_DIRECTION(LightDirection1, "Light Direction 1", "Lights") 		= float3(-0.70721757439004396f, -0.35190930976021367f, -0.61319094919768080f);
#include "used_float3.fxh"
DECLARE_LIGHT_COLOR(LightColor1, "Light Color 1", "Lights")    					= float3(0, 0, 0);
#include "used_float3.fxh"
DECLARE_LIGHT_INTESITY(LightIntensity1, "Light Intensity 1", "Lights", 0, 100)	= float(0.0);
#include "used_float.fxh"

// light3
DECLARE_LIGHT_DIRECTION(LightDirection2, "Light Direction 2", "Lights") 		= float3(-0.12796169294712939f, -0.32960456030912610f, 0.93540720489075369f);
#include "used_float3.fxh"
DECLARE_LIGHT_COLOR(LightColor2, "Light Color 2", "Lights")    					= float3(0, 0, 0);
#include "used_float3.fxh"
DECLARE_LIGHT_INTESITY(LightIntensity2, "Light Intensity 2", "Lights", 0, 100)	= float(0.0);
#include "used_float.fxh"

void add_maya_lights_to_light_data(
	inout s_lighting_components lighting_data)
{
	lighting_data.light_direction_specular_scalar[lighting_data.light_component_count+0]= float4(-LightDirection0.xyz, pi);
	lighting_data.light_direction_specular_scalar[lighting_data.light_component_count+1]= float4(-LightDirection1.xyz, pi);
	lighting_data.light_direction_specular_scalar[lighting_data.light_component_count+2]= float4(-LightDirection2.xyz, pi);

	lighting_data.light_intensity_diffuse_scalar[lighting_data.light_component_count+0]= float4(LightColor0.rgb * LightIntensity0, 1.0f);
	lighting_data.light_intensity_diffuse_scalar[lighting_data.light_component_count+1]= float4(LightColor1.rgb * LightIntensity1, 1.0f);
	lighting_data.light_intensity_diffuse_scalar[lighting_data.light_component_count+2]= float4(LightColor2.rgb * LightIntensity2, 1.0f);

	lighting_data.light_component_count+= 3;
}

#endif

#endif 	// !defined(__LIGHTING_FXH)