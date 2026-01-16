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

DECLARE_SAMPLER( combo_map, "Combo Map (AO, Rough, Metallic, Cov Mask)", "Combo Map", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"

#if (defined(ANISO) || defined(CLEARCOAT) || (defined(SELFILLUM) && !defined(COLOURED_ILLUM)))
	DECLARE_SAMPLER( combo_map_2, "Combo Map (Coat Rough, Coat Mask, Aniso, Illum)", "Combo Map 2", "shaders/default_bitmaps/bitmaps/color_white.tif");
	#include "next_texture.fxh"
#endif

#if defined(SELFILLUM)
	#ifdef COLOURED_ILLUM
		DECLARE_SAMPLER(illum_map, "Illum Map", "Illum Map", "shaders/default_bitmaps/bitmaps/color_white.tif");
		#include "next_texture.fxh"
	#endif
	DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
	#include "used_float3.fxh"
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

#ifdef ANISO
	DECLARE_FLOAT_WITH_DEFAULT(anisotropy,	"Anisotropy", "", -1, 1, float(0.0));
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

#ifdef IRIDESCENT
    DECLARE_RGB_COLOR_WITH_DEFAULT(specular_colour,	"Covenant Colour Tint", "", float3(1.0,1.0,1.0));
    #include "used_float3.fxh"
    DECLARE_RGB_COLOR_WITH_DEFAULT(fresnel_colour,	"Fresnel Colour", "", float3(1.0,1.0,1.0));
    #include "used_float3.fxh"

	#if defined(NORMAL_NOISE)
		DECLARE_SAMPLER( normal_noise_map, "Normal Noise Map", "Normal Noise Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
		#include "next_texture.fxh"
		DECLARE_FLOAT_WITH_DEFAULT(noise_strength,	"Noise Strength", "", 0, 1, float(1.0));
		#include "used_float.fxh"
	#endif
#endif

#if defined(ALPHA_CLIP) 
	DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
	#include "used_float.fxh"

	#if defined(ALPHA_CLIP_ALBEDO_ONLY)
		DECLARE_FLOAT_WITH_DEFAULT(alpha_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
		#include "used_float.fxh"
	#endif
#endif

DECLARE_FLOAT_WITH_DEFAULT(alpha_scale, "Alpha Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

struct s_shader_data {
	s_common_shader_data common;
	float4 albedo;
	float4 combo;
#if (defined(ANISO) || defined(CLEARCOAT) || defined(SELFILLUM))
	float4 combo_2;
#endif
#ifdef IRIDESCENT
	float3 f82;
#endif
#ifdef CLEARCOAT
	float3 clearcoat_normal;
#endif
#ifdef ANISO
	float aniso;
#endif
	//float3 f0;
};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
#ifdef PARALLAX
	uv = ParallaxMapping(pixel_shader_input, shader_data, combo_map);
#endif
	//float2 uv2 = pixel_shader_input.texcoord.zw;
#ifdef BASIC_DETAIL_MAPS
	float2 uv_det = uv;
#endif

	// Calculate the normal map value
#ifdef NORMAL_NOISE
	float3 normal_chameleon = 0;
#endif
    {
		// Sample normal maps
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample2DNormal(normal_map, normal_uv);
		// Use the base normal map
#ifdef CLEARCOAT
		shader_data.clearcoat_normal = mul(base_normal, shader_data.common.tangent_frame);
#endif

#ifdef BASIC_DETAIL_MAPS
		base_normal = CompositeDetailNormalMap(base_normal, detail_normal_map, transform_texcoord(uv_det, detail_normal_map_transform), detail_normal_strength);
#endif
		shader_data.common.normal = base_normal;

		// Transform from tangent space to world space
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
		
#ifdef NORMAL_NOISE
		normal_chameleon = mul(CompositeDetailNormalMap(base_normal, normal_noise_map, transform_texcoord(uv, normal_noise_map_transform), noise_strength), shader_data.common.tangent_frame);
#endif
    }

    {// Sample color map and combo maps.
	    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
		shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);

#ifdef BASIC_DETAIL_MAPS
		float4	detail_albedo =	sample2DGamma(detail_color_map, transform_texcoord(uv_det, detail_color_map_transform));
		shader_data.common.albedo = albedo_colour_overlay(shader_data.common.albedo, detail_albedo);
#endif

		shader_data.common.albedo.rgb *= albedo_tint;

		float2 combo_map_uv	= transform_texcoord(uv, combo_map_transform);
		shader_data.combo 	= sample2D(combo_map, combo_map_uv);
#if (defined(ANISO) || defined(CLEARCOAT) || defined(SELFILLUM))
		float2 combo_map_uv_2 = transform_texcoord(uv, combo_map_2_transform);
		shader_data.combo_2 = sample2D(combo_map_2, combo_map_uv_2);
#endif

		shader_data.combo.r = saturate(ao_scale * shader_data.combo.r + (1 - ao_scale));
		shader_data.combo.g = clamp((roughness_scale * shader_data.combo.g) + roughness_offset, 0.03, 1);
		shader_data.combo.b = saturate((metallic_scale * shader_data.combo.b) + metallic_offset);

#ifdef CLEARCOAT
		shader_data.combo_2.x = clamp((roughness_scale_coat * shader_data.combo_2.x) + roughness_offset_coat, 0.005, 1);
#endif

#ifdef ANISO
		shader_data.aniso = clamp(anisotropy, -1.0, 1.0) * shader_data.combo_2.z;
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

#ifdef IRIDESCENT
		{
			float cov_mask = shader_data.combo.w;
			shader_data.common.albedo.rgb *= lerp(1, specular_colour, cov_mask);
			
	#ifdef NORMAL_NOISE
			shader_data.common.normal = lerp(shader_data.common.normal, normal_chameleon, cov_mask);
	#endif
			shader_data.f82 = fresnel_colour;
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
	
	// Sample combo map 
	//R = AO
	//G = Roughness
	//B = Metalicness
	//A = Cov Mask
	float4 combo 	= shader_data.combo;

#if (defined(ANISO) || defined(CLEARCOAT) || defined(SELFILLUM))
	// Sample second combo map
	//R = CC Roughness
	//G = CC Mask
	//B = Aniso Mask
	//A = emissive
    float4 combo_2 	= shader_data.combo_2;
#endif
#ifdef ANISO
	float aniso = shader_data.aniso;
#endif

	float3 specular_color = lerp(clamp(spec_coeff, 0.0, 0.07), albedo.rgb, combo.b);	//get f0 from albedo with metalness mask.

#ifdef IRIDESCENT
	float3 f82 = shader_data.f82;
#endif

#ifdef CLEARCOAT //adjust f0 to account for clearcoat
	specular_color = lerp(specular_color, pow(1 - 5 * sqrt(specular_color), 2) / pow(5 - sqrt(specular_color), 2), combo_2.y);

	float3 cc_normal = shader_data.clearcoat_normal;
#endif

    
	//calculate specular and diffuse BRDFs
	float3 brdf = combo.r;
	float3 reflection_dif = 0.0f;

	float4 material_parameters = float4(
		combo.y,
#if  defined(CLEARCOAT)
		combo_2.x,
		combo_2.y,
#else
		0.0f, 0.0f,
#endif
#ifdef ANISO
		aniso
#else
		0.0f
#endif
	);

	calc_pbr(
			brdf,
			reflection_dif,
			shader_data.common,
#ifdef CLEARCOAT
			cc_normal,
#else
			(float3)0.0,
#endif
			specular_color,
#ifdef IRIDESCENT
			float4(f82, combo.w),
#else
			(float4)0.0f,
#endif
			material_parameters
			);

	// sample reflection
	float3 view = shader_data.common.view_dir_distance.xyz;
	float cosTheta = saturate(dot(normal, -view));
	float3 rVec = reflect(view, normal);
	rVec.y *= -1;
	float mip_index = pow(combo.g, 0.4545454545f) * 8;//(pow((combo.g - 1.0), 3.0) + 1.0) * 8.0;//max(base_lod, specular_reflectance_and_roughness.w * env_roughness_scale * 9);
	//float mip_index = pow(rough, 1 / 2.2) * 8.0f;
	float4 reflectionMap = sampleCUBELOD(reflection_map, rVec, mip_index);
	float gloss = 1.0 - combo.g;
	float3 fresnel = fresnel_schlick_roughness(specular_color, cosTheta, gloss);
#ifdef IRIDESCENT
	fresnel = lerp(fresnel, saturate(fresnel - fresnel_lasagne(specular_color, f82, cosTheta)), combo.w);
#endif

	float3 reflection = reflectionMap.a * reflectionMap.rgb * EnvBRDFApprox(fresnel, combo.g, max(dot(normal, -view), cosTheta)) * reflection_dif;

#ifdef CLEARCOAT
	float cosThetaCC = saturate(dot(cc_normal, -view));
	float glossCC = (1 - combo_2.x);
	float3 fresnelCC = EnvBRDFApprox(fresnel_schlick_roughness((float4)0.04f, glossCC, cosThetaCC), combo_2.x, cosTheta);
	float4 reflectionMapCC = sampleCUBELOD(reflection_map, rVec, pow(combo_2.x, 0.4545454545f) * 8);
	float3 reflectionCC = reflectionMapCC.a * reflectionMapCC.rgb * EnvBRDFApprox(fresnelCC, combo.w, max(dot(cc_normal, -view), 0.0)) * reflection_dif * combo_2.y;

	reflection *= (1 - fresnelCC) * combo_2.y;
	reflection += reflectionCC;
#endif

	//.. Finalize Output Color
    float4 out_color;
	out_color.a   = albedo.a * alpha_scale;
	 
	out_color.rgb = brdf + reflection;

	#if defined(SELFILLUM)
		#ifdef COLOURED_ILLUM
			float2 color_map_uv = transform_texcoord(uv, color_map_transform);
			float3 selfIllum = sample2DGamma(illum_map, transform_texcoord(uv, illum_map_transform)).rgb;
			float3 selfIllum *= si_color * si_amount;
		#else
			float3 selfIllum = shader_data.combo_2.w * si_color * si_amount;
		#endif
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
