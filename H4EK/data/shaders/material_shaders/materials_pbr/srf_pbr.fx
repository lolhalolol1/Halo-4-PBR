// File:	 srf_pbr
// Author:	 Oli :D (based on srf_blinn, set up by hocoulby)
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
DECLARE_SAMPLER(color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"

#if defined(BASIC_DETAIL_MAPS)
	DECLARE_SAMPLER(detail_color_map, "Detail Color Map", "Detail Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
	#include "next_texture.fxh"
	DECLARE_SAMPLER(detail_normal_map, "Detail Normal Map", "Detail Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
	#include "next_texture.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(detail_normal_strength, "Detail Normal Strength", "detail_normals", 0, 0.0, float(1.0));
	#include "used_float.fxh"
#endif

DECLARE_SAMPLER( combo_map, "Combo Map", "Combo Map", "shaders/default_bitmaps/bitmaps/rough_no_metal_orm.tif.tif");
#include "next_texture.fxh"

#if defined(SELFILLUM)
	DECLARE_SAMPLER(self_illum_map, "Self Illum Map", "Self Illum Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
	#include "next_texture.fxh"

	DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
	#include "used_float3.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(si_amount,	"SelfIllum Amount", "", 0, 1, float(1.0));
	#include "used_float.fxh"
#endif

DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"

#ifdef TINTABLE_VERSION
	DECLARE_SAMPLER(tint_map, "Tint Map", "Tint Map", "shaders/default_bitmaps/bitmaps/color_white.tif");
	#include "next_texture.fxh"

	DECLARE_RGB_COLOR_WITH_DEFAULT(base_color,	"Base Color", "", float3(1,1,1));
	#include "used_float3.fxh"

	// Diffuse Primary and Secondary Change Colors
	#if defined(cgfx) || defined(ARMOR_PREVIS)
		DECLARE_RGB_COLOR_WITH_DEFAULT(tmp_primary_cc,	"Test Primary Color", "", float3(1,1,1));
		#include "used_float3.fxh"
		DECLARE_RGB_COLOR_WITH_DEFAULT(tmp_secondary_cc,	"Test Secondary Color", "", float3(1,1,1));
		#include "used_float3.fxh"
	#endif
#endif 
// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(roughness_scale, "Roughness Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(roughness_offset, "Roughness Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"

#ifdef CLEARCOAT
	DECLARE_FLOAT_WITH_DEFAULT(roughness_scale_coat, "Coat Roughness Scale", "", 0, 1, float(1.0));
	#include "used_float.fxh"

	DECLARE_FLOAT_WITH_DEFAULT(roughness_offset_coat, "Coat Roughness Offset", "", 0, 1, float(0.0));
	#include "used_float.fxh"
#endif

DECLARE_FLOAT_WITH_DEFAULT(metallic_scale, "Metallic Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(metallic_offset, "Metallic Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ao_scale, "AO Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(emissive, "Emissive Multiplier", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity, "Reflection Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
#endif



DECLARE_FLOAT_WITH_DEFAULT(spec_coeff, "Specular Coefficient", "", 0.0, 0.07, float(0.04));
#include "used_float.fxh"

#if defined(COVENANT)
	DECLARE_SAMPLER(cov_mask_map, "Cov Mask Map", "", "shaders/default_bitmaps/bitmaps/color_white.bitmap")
    #include "next_texture.fxh"

    DECLARE_RGB_COLOR_WITH_DEFAULT(front_color,	"Front Color Tint", "", float3(0.0,0.14,1.0));
    #include "used_float3.fxh"
    DECLARE_FLOAT_WITH_DEFAULT(front_power, "Front Offset", "", 0, 1, float(0.3));
    #include "used_float.fxh"

    DECLARE_RGB_COLOR_WITH_DEFAULT(middle_color, "Middle Color Tint", "", float3(0.98,0.05, 0.2));
    #include "used_float3.fxh"
    DECLARE_FLOAT_WITH_DEFAULT(middle_power, "Middle Offset", "", 0, 1, float(0.7));
    #include "used_float.fxh"

    DECLARE_RGB_COLOR_WITH_DEFAULT(rim_color,	"Rim Color Tint", "", float3(1.0,1.0,1.0));
    #include "used_float3.fxh"
    DECLARE_FLOAT_WITH_DEFAULT(rim_power,	"Rim Offset", "", 0, 1, float(1.0));
    #include "used_float.fxh"

	#if defined(NORMAL_NOISE)
	DECLARE_SAMPLER( normal_noise_map, "Normal Noise Map", "Normal Noise Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
	#include "next_texture.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(noise_strength,	"Noise Strength", "", 0, 1, float(1.0));
    #include "used_float.fxh"
	#endif
#endif

///
#if defined(ALPHA_CLIP) 
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"

#if defined(ALPHA_CLIP_ALBEDO_ONLY)
DECLARE_FLOAT_WITH_DEFAULT(alpha_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"

#endif
#endif

struct s_shader_data {
	s_common_shader_data common;
	float4 albedo;
	float4 combo;
#ifdef CLEARCOAT
	float3 clearcoat_normal;
#endif
	//float3 f0;
};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
	//float2 uv2 = pixel_shader_input.texcoord.zw;
#ifdef BASIC_DETAIL_MAPS
	float2 uv_det = uv;
#endif
	//shader_data.common.shaderValues.x = 1.0f; 			// Default specular mask



	// Calculate the normal map value
#ifdef NORMAL_NOISE
	float3 normal_chameleon = 0;
#endif
    {
		// Sample normal maps
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample2DNormal(normal_map, normal_uv);
		// Use the base normal map

#ifdef BASIC_DETAIL_MAPS
#ifdef CLEARCOAT
		shader_data.clearcoat_normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
#endif
		base_normal = CompositeDetailNormalMap(base_normal, detail_normal_map, transform_texcoord(uv_det, detail_normal_map_transform), detail_normal_strength);
#endif
		shader_data.common.normal = base_normal;



		// Transform from tangent space to world space
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
		
#ifdef NORMAL_NOISE
		normal_chameleon = mul(CompositeDetailNormalMap(base_normal, normal_noise_map, transform_texcoord(uv, normal_noise_map_transform), noise_strength), shader_data.common.tangent_frame);
#endif
    }

    {// Sample color map.
	    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
		shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);

#ifdef BASIC_DETAIL_MAPS
			float4	detail_albedo =	sample2DGamma(detail_color_map, transform_texcoord(uv_det, detail_color_map_transform));
			shader_data.common.albedo = albedo_colour_overlay(shader_data.common.albedo, detail_albedo);
#endif

		shader_data.common.albedo.rgb *= albedo_tint;

		float2 combo_map_uv	= transform_texcoord(uv, combo_map_transform);
		shader_data.combo 	= sample2D(combo_map, combo_map_uv);

		shader_data.combo.r = saturate(ao_scale * shader_data.combo.r);
		shader_data.combo.g = clamp((roughness_scale * shader_data.combo.g) + roughness_offset, 0.005, 1);
		shader_data.combo.b = saturate((metallic_scale * shader_data.combo.b) + metallic_offset);

		#ifdef CLEARCOAT
		shader_data.combo.w = clamp((roughness_scale_coat * shader_data.combo.w) + roughness_offset_coat, 0.005, 1);
		#endif
		
		#ifdef TINTABLE_VERSION
			float4 control_map = sample2DGamma(tint_map, color_map_uv);
			// determine surface color
			// primary change color engine mappings, using temp values in maya for prototyping
			float4 primary_cc = 1.0;
			float3 secondary_cc = 1.0f;

			#if defined(cgfx)  || defined(ARMOR_PREVIS)
				primary_cc   = float4(tmp_primary_cc, 1.0);
				secondary_cc = float4(tmp_secondary_cc,1.0);
			#else
				primary_cc   = ps_material_object_parameters[0];
				secondary_cc = ps_material_object_parameters[1];
			#endif

			float3 surface_colors[3] = {base_color.rgb,
										secondary_cc.rgb,
										primary_cc.rgb};
			float3 surface_color;
			
			surface_color = primary_cc * control_map.r;
			surface_color += secondary_cc * control_map.g;
			surface_color += base_color * control_map.b;
			
			// output color
			shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, shader_data.common.albedo.rgb * surface_color, saturate(control_map.r + control_map.g + control_map.b));
		#endif

		#ifdef COVENANT
			{
				float cov_mask = sample2D(cov_mask_map, color_map_uv).r;

				float3 ch_colour[3] = 
				{
					front_color,
					middle_color,
					rim_color,
				};
				float offsets_div[3] =
				{
					front_power,
					middle_power,
					rim_power,
				};
			#ifdef NORMAL_NOISE
				shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, shader_data.common.albedo.rgb * calcChameleon(normal_chameleon, -shader_data.common.view_dir_distance.xyz, offsets_div, ch_colour), cov_mask);
			#else
				shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, calcChameleon(shader_data.common.normal, -shader_data.common.view_dir_distance.xyz, offsets_div, ch_colour), cov_mask);
			#endif
			}
		#endif	
		
		//shader_data.common.albedo.rgb *= albedo_tint.rgb;
	 
	 float alpha;
#if defined(FIXED_ALPHA)
        float2 alpha_uv		= uv;
		alpha	= sample2DGamma(color_map, alpha_uv).a;
#else
        alpha	= shader_data.common.albedo.a;
#endif

#if defined(VERTEX_ALPHA)
		alpha *= shader_data.common.vertexColor.a;
#endif

        #if defined(ALPHA_CLIP) && defined(ALPHA_CLIP_ALBEDO_ONLY)
                // Tex kill non-opaque pixels in albedo pass; tex kill opaque pixels in all other passes
                if (shader_data.common.shaderPass != SP_SINGLE_PASS_LIGHTING)
                {
                    // Clip anything that is less than the alpha threshold in the alpha
                    clip(alpha - alpha_threshold);
                }
                else
                {
                    // Reverse the order, so anything larger than the near-white threshold is clipped
                    clip(alpha_threshold - alpha);
					//still clip the low end
					clip(alpha - clip_threshold);

					//renormalize the alpha space so we get a better control.
					alpha = alpha / alpha_threshold;
                }
        #elif defined(ALPHA_CLIP)
                // Tex kill pixel
                clip(alpha - clip_threshold);
        #endif
        
        shader_data.common.albedo.a = alpha;

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
	
	// Sample combo map, r = AO, g = roughness, b = metalicness, a = depends on template
	float4 combo 	= shader_data.combo;
    
     float3 specular = 0.0f;

	float cavity_ao = saturate(combo.r);

	float rough = combo.g;
	float metallic = combo.b; 

	float3 specular_color = lerp(spec_coeff, albedo.rgb, metallic);	//get f0 from albedo with metalness mask.

#ifdef CLEARCOAT //adjust f0 to account for clearcoat
	specular_color = pow(1 - 5 * sqrt(specular_color), 2) / pow(5 - sqrt(specular_color), 2);
#endif

    
	//calculate diffuse
	float3 brdf = cavity_ao;
	float3 reflection_dif = 0.0f;
#ifdef CLEARCOAT
	calc_pbr(brdf, reflection_dif, shader_data.common, normal, float4(specular_color, combo.w), rough);
#else
	calc_pbr(brdf, reflection_dif, shader_data.common, normal, specular_color, rough);
#endif
	// sample reflection
	float3 view = shader_data.common.view_dir_distance.xyz;
		 
	float3 rVec = reflect(view, normal);
	rVec.y *= -1;
	float mip_index = (pow((rough - 1.0), 3.0) + 1.0) * 8.0;//max(base_lod, specular_reflectance_and_roughness.w * env_roughness_scale * 9);
	//float mip_index = pow(rough, 1 / 2.2) * 8.0f;
	float4 reflectionMap = sampleCUBELOD(reflection_map, rVec, mip_index);
	float gloss = 1.f - rough;
	float3 fresnel = FresnelSchlickWithRoughness(specular_color, -view, normal, gloss);

	float3 reflection = reflectionMap.a * reflectionMap.rgb * EnvBRDFApprox(fresnel, rough, max(dot(normal, -view), 0.0)) * reflection_dif;

#ifdef CLEARCOAT
	float3 fresnelCC = FresnelSchlickWithRoughness((float4)0.04f, -view, normal, (1 - combo.w));
	float3 reflectionCC = reflectionMap.a * reflectionMap.rgb * EnvBRDFApprox(fresnelCC, combo.w, max(dot(normal, -view), 0.0)) * reflection_dif;

	reflection *= (1 - fresnelCC);
	reflection += reflectionCC;
#endif

	//.. Finalize Output Color
    float4 out_color;
	out_color.a   = albedo.a;
	 
	out_color.rgb = brdf + reflection;

	#if defined(SELFILLUM)
		float3 selfIllumColor = sample2DGamma(self_illum_map, transform_texcoord(uv, color_map_transform)).rgb;
		float3 selfIllum = selfIllumColor * si_color * si_amount;	
		out_color.rgb += selfIllum;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(selfIllum);
	#else
		shader_data.common.selfIllumIntensity = 0;
	#endif
	//out_color.rgb = metallic;

	
	//boost tint color based on distance
	//Oli: commented this out 'cause it's not physically plausible and that bothers me. Will add back if it's required.
	/*#ifdef TINTABLE_VERSION
		float4 primary_cc = 1.0;

		#if defined(cgfx)  || defined(ARMOR_PREVIS)
			primary_cc   = float4(tmp_primary_cc, 1.0);
		#else
			primary_cc   = ps_material_object_parameters[0];
		#endif
		out_color.rgb = lerp(out_color.rgb  ,  out_color.rgb +  pow(saturate(dot(normal, float3(0,0,1))),3) * reflectionMap.rgb * reflectionMap.a * 5, pow(saturate((shader_data.common.view_dir_distance.w ) / 25), 2));
	#endif*/
	return out_color;
}


#include "techniques.fxh"
