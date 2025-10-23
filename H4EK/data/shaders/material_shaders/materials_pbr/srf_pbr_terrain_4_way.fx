// File:	 srf_pbr_terrain_4_way
// Author:	 Oli :D
//
// Specular BRDF: 	GGX 
// Diffuse BRDF: 	Hammon

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting_pbr.fxh"
#include "lighting/oli_misc_functions.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER(blend_map, "Blend Map RGBA", "", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(red_uv_tile,         "Red Channel UV tile",      "", 0, 32, 1.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(green_uv_tile,         "Green Channel UV tile",      "", 0, 32, 1.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(blue_uv_tile,         "Blue Channel UV tile",      "", 0, 32, 1.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_uv_tile,         "Alpha Channel UV tile",      "", 0, 32, 1.0);
#include "used_float.fxh"

DECLARE_SAMPLER_2D_ARRAY(color_map, "Color Map Array", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
#if defined(DETAIL_ALBDEO)
	DECLARE_SAMPLER_2D_ARRAY(detail_color_map, "Detail Color Map Array", "Detail Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
	#include "next_texture.fxh"
#endif

DECLARE_FLOAT_WITH_DEFAULT(red_diffuse_map,     "Red Channel Albedo Map",   "", 0, 4, 0.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(green_diffuse_map,   "Green Channel Albedo Map", "", 0, 4, 1.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(blue_diffuse_map,    "Blue Channel Albedo Map",   "", 0, 4, 2.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_diffuse_map,   "Alpha Channel Albedo Map",   "", 0, 4, 4.0);
#include "used_float.fxh"

DECLARE_SAMPLER_2D_ARRAY(normal_map, "Normal Map Array", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(red_normal_map,      "Red Channel Normal Map",   "", 0, 4, 0.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(green_normal_map,    "Green Channel Normal Map", "", 0, 4, 1.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(blue_normal_map,     "Blue Channel Normal Map",   "", 0, 4, 2.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_normal_map,    "Alpha Channel Normal Map",   "", 0, 4, 4.0);
#include "used_float.fxh"

DECLARE_SAMPLER_2D_ARRAY(combo_map, "Combo Map Array", "Combo Map", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(red_combo_map,     "Red Channel Control Map",  "", 0, 4, 0.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(green_combo_map,   "Green Channel Control Map","", 0, 4, 1.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(blue_combo_map,    "Blue Channel Control Map",  "", 0, 4, 2.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_combo_map,   "Alpha Channel Control Map",  "", 0, 4, 4.0);
#include "used_float.fxh"

DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"

// Diffuse
//DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
//#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(roughness_scale, "Roughness Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(roughness_offset, "Roughness Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(metallic_scale, "Metallic Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(metallic_offset, "Metallic Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ao_scale, "AO Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity, "Reflection Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

struct s_shader_data {
	s_common_shader_data common;
	float4 albedo;
	float4 combo;
	//float3 f0;
};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

	//shader_data.common.shaderValues.x = 1.0f; 			// Default specular mask
	float4 blend = sample2D(blend_map, transform_texcoord(uv, blend_map_transform));
	//blend.xyz *= blend.w;
	blend.w = 1 - blend.w;
	float blend_sum = blend.x + blend.y + blend.z + blend.w;
	blend.xyzw= (blend.xyzw) / blend_sum;
	float blend_black = 1 - saturate(blend.r + blend.g + blend.b + blend.w); 

	float2 mat_uv[4] = 	{
							transform_texcoord(uv, red_uv_tile),
							transform_texcoord(uv, green_uv_tile),
							transform_texcoord(uv, blue_uv_tile),
							transform_texcoord(uv, alpha_uv_tile)
					   	};

	// Calculate the normal map value
    {
		// Sample normal maps
		float3 normals[4] = {
								sample3DNormal(normal_map, float3(mat_uv[0], red_normal_map)).xyz * blend.x,
								sample3DNormal(normal_map, float3(mat_uv[1], green_normal_map)).xyz * blend.y,
								sample3DNormal(normal_map, float3(mat_uv[2], blue_normal_map)).xyz * blend.z,
								sample3DNormal(normal_map, float3(mat_uv[3], alpha_normal_map)).xyz * blend.w
							};
        //float3 base_normal = sample2DNormal(normal_map, normal_uv);
		// Use the base normal map
		shader_data.common.normal = normals[0] + normals[1] + normals[2] + normals[3];

		// Transform from tangent space to world space
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }

    {// Sample color map.



		float4 colours[4] = {
								sample3DGamma(color_map, float3(mat_uv[0], red_diffuse_map)) * blend.x,
								sample3DGamma(color_map, float3(mat_uv[1], green_diffuse_map)) * blend.y,
								sample3DGamma(color_map, float3(mat_uv[2], blue_diffuse_map)) * blend.z,
								sample3DGamma(color_map, float3(mat_uv[3], alpha_diffuse_map)) * blend.w
							};

		shader_data.common.albedo = saturate(colours[0] + colours[1] + colours[2] + colours[3]);

		/*#ifdef DETAIL_ALBDEO
			float4	detail_albedo =	sample2DGamma(detail_color_map, transform_texcoord(uv, detail_color_map_transform));
			shader_data.common.albedo.rgb *= detail_albedo.rgb;
			shader_data.common.albedo.w= shader_data.common.albedo.w * detail_albedo.w;
		#endif*/

		//shader_data.common.albedo.rgb *= albedo_tint;

		float4 combos[4] = {
								sample3D(combo_map, float3(mat_uv[0], red_combo_map)) * blend.x,
								sample3D(combo_map, float3(mat_uv[1], green_combo_map)) * blend.y,
								sample3D(combo_map, float3(mat_uv[2], blue_combo_map)) * blend.z,
								sample3D(combo_map, float3(mat_uv[3], alpha_combo_map)) * blend.w
							};
		shader_data.combo 	= combos[0] + combos[1] + combos[2] + combos[3];

		shader_data.combo.r = saturate(ao_scale * shader_data.combo.r);
		shader_data.combo.g = saturate((roughness_scale * shader_data.combo.g) + roughness_offset);
		shader_data.combo.b = saturate((metallic_scale * shader_data.combo.b) + metallic_offset);
		//shader_data.common.shaderValues.x = shader_data.combo.b;

		//shader_data.f0 = lerp(0.04, shader_data.albedo, shader_data.combo.b);
		
		
		//shader_data.common.albedo.rgb *= albedo_tint.rgb;

        shader_data.common.shaderValues.y = shader_data.combo.b; 
        shader_data.common.shaderValues.x = shader_data.combo.g; 
	}
}

 
 
float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data) 
{
	float2 uv = pixel_shader_input.texcoord.xy;
 
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;
	
	// Sample combo map, r = metalicness, g = cavity multiplier (fake AO), b = Self Illume map, a = roughness
	float4 combo 	= shader_data.combo;
    
     float3 specular = 0.0f;

	float cavity_ao = combo.r;
	float rough = combo.g;
	float metallic = combo.b; 

	// using blinn specular model
	float3 specular_color = lerp(0.04f, albedo.rgb, metallic);
    
	//calculate diffuse
	float3 brdf = cavity_ao;
	float3 reflection_dif = 0.0f;
	calc_pbr(brdf, reflection_dif,  shader_data.common, normal, specular_color, rough);
	
	// sample reflection
	float3 view = shader_data.common.view_dir_distance.xyz;
		 
	float3 rVec = reflect(view, normal);
	rVec.y                  *= -1;
	float mip_index = (pow((rough - 1.0), 3.0) + 1.0) * 8.0;//max(base_lod, specular_reflectance_and_roughness.w * env_roughness_scale * 9);
	//float mip_index = pow(rough, 1 / 2.2) * 8.0f;
	float4 reflectionMap = sampleCUBELOD(reflection_map, rVec, mip_index);
	float gloss = 1.f - rough;
	float3 fresnel = FresnelSchlickWithRoughness(specular_color, -view, normal, gloss);
	float3 reflection = reflectionMap.a * reflectionMap.rgb * EnvBRDFApprox(fresnel, rough, max(dot(normal, -view), 0.0)) * reflection_dif;

	//.. Finalize Output Color
    float4 out_color;
	out_color.a   = albedo.a;
	 
	out_color.rgb = brdf + reflection;
	return out_color;
}


#include "techniques.fxh"
