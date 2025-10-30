// File:	 srf_pbr
// Author:	 Oli :D (based on srf_blinn, set up by hocoulby)
//
// Specular BRDF: 	GGX 
// Diffuse BRDF: 	Hammon

// Core Includes
#define SKIN_BRDF
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

DECLARE_SAMPLER( combo_map, "Combo Map (AO, Rough, Translucence, Curvature)", "Combo Map", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(roughness_scale, "Roughness Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(roughness_offset, "Roughness Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ss_normal_mip, "SS Normal Mip", "", 0, 4, float(2.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ss_distortion, "SS Distortion", "", 0, 1, float(0.5));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ss_power, "SS Power", "", 0, 100, float(5.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(ss_colour,		"SS Colour", "", float3(1,0,0));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ao_scale, "AO Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER(skin_lut, "skin lut", "skin lut", "shaders/default_bitmaps/bitmaps/lut_direct.tif");
#include "next_texture.fxh"

#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
#endif

DECLARE_FLOAT_WITH_DEFAULT(spec_coeff, "Specular Coefficient", "", 0.0, 0.07, float(0.04));
#include "used_float.fxh"

#if defined(ALPHA_CLIP) 
	DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
	#include "used_float.fxh"

	#if defined(ALPHA_CLIP_ALBEDO_ONLY)
		DECLARE_FLOAT_WITH_DEFAULT(alpha_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
		#include "used_float.fxh"
	#endif
#endif

float3 sample2DVectorLOD(texture_sampler_2d s, float3 uvw)
{
	float3 value = sample2DLOD(s, uvw.xy, uvw.z).xyz;

#if defined(NORMALMAPS_REQUIRE_BIAS)
	value -= 0.5 / 255.0;
	value = bx2(value);
#endif

	return value;
}

float3 sample2DNormalLOD(texture_sampler_2d s, float3 uvw)
{
	float3 normal = sample2DVectorLOD(s, uvw);

#if !defined(NORMALMAPS_HAVE_Z)
	normal.z = sqrt(saturate(1.0f + dot(normal.xy, -normal.xy)));
#else
	normal= normalize(normal);
#endif

	return normal;
}

struct s_shader_data {
	s_common_shader_data common;
	float3 smooth_normal;
	float4 albedo;
	float4 combo;
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
    {
		// Sample normal maps
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample2DNormal(normal_map, normal_uv);
		// Use the base normal map

#ifdef BASIC_DETAIL_MAPS
		base_normal = CompositeDetailNormalMap(base_normal, detail_normal_map, transform_texcoord(uv_det, detail_normal_map_transform), detail_normal_strength);
#endif
		shader_data.common.normal = base_normal;
		shader_data.smooth_normal = sample2DNormalLOD(normal_map, float3(normal_uv, ss_normal_mip));

		// Transform from tangent space to world space
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
		shader_data.smooth_normal = mul(shader_data.smooth_normal, shader_data.common.tangent_frame);
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

		shader_data.combo.r = saturate(ao_scale * shader_data.combo.r + (1 - ao_scale));
		shader_data.combo.g = clamp((roughness_scale * shader_data.combo.g) + roughness_offset, 0.03, 1);
	 
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
	float3 smooth_normal  = shader_data.smooth_normal;
	float3 viewDir = -shader_data.common.view_dir_distance.xyz;
	// Sample combo map 
	//R = AO
	//G = Roughness
	//B = Metalicness
	//A = Height
	float4 combo 	= shader_data.combo;

	float3 specular_color = (float3)clamp(spec_coeff, 0.0, 0.07);	//get f0 from albedo with metalness mask.
    
	//calculate specular and diffuse BRDFs
	float3 brdf = 0;
	float3 fresnel;
/*	calc_skin(
			brdf,
			reflection_dif,
			shader_data.common,
			normal,
			specular_color,
			combo
			);*/
	float3 reflection_dif = 0;

	brdf = VMFSkinPBR(
			reflection_dif,
			shader_data.common,
			smooth_normal,
			specular_color,
			combo,
			ss_distortion,
			ss_power,
			ss_colour,
			skin_lut
			);


	for (uint i = 0; i < shader_data.common.lighting_data.light_component_count; i++)   //Loop to account for multiple light sources.
    {
        float4 direction = shader_data.common.lighting_data.light_direction_specular_scalar[i];
        float4 intensity_diffuse_scalar = shader_data.common.lighting_data.light_intensity_diffuse_scalar[i];

		float3 spec = calc_ggx(normal, viewDir, direction.xyz, intensity_diffuse_scalar.xyz * direction.w, specular_color, combo.y, fresnel);

		float NdotL_blur = dot(smooth_normal, direction.xyz);

        float3 skin_dif = sample2D(skin_lut, float2(mad(NdotL_blur, 0.5f, 0.5f), combo.w)).xyz;
		skin_dif = float3(
			lerp(skin_dif.z, skin_dif.x, ss_colour.x),
			lerp(skin_dif.y, skin_dif.x, ss_colour.y),
			lerp(skin_dif.z, skin_dif.x, ss_colour.z)
		) * 0.5f - 0.25f;		

        float normalSmoothFactor = saturate(1.0 - NdotL_blur);
        normalSmoothFactor *= normalSmoothFactor;

        float3 view_normalG = normalize(lerp(normal, normal, 0.3 + 0.7 * normalSmoothFactor));
        float3 view_normalB = normalize(lerp(normal, smooth_normal, normalSmoothFactor));
        float NoL_ShadeG = saturate(dot(view_normalG, direction.xyz));
        float NoL_ShadeB = saturate(dot(view_normalB, direction.xyz));

        float3 rgbNdotL = float3(saturate(NdotL_blur), NoL_ShadeG, NoL_ShadeB);
        skin_dif = saturate(skin_dif + rgbNdotL);

		float3 sss_H = normalize(direction.xyz + normal * ss_distortion);
		float backlight = pow(saturate(dot(viewDir, -sss_H)), ss_power) * combo.z;
		float3 translucence = backlight * ss_colour;

		float3 diffuse = (skin_dif + translucence) * (albedo.xyz / pi) * (1 - fresnel) * intensity_diffuse_scalar.xyz;

		brdf += diffuse + spec;
    }

	// sample reflection
	float3 view = shader_data.common.view_dir_distance.xyz;
	
	float3 rVec = reflect(view, normal);
	rVec.y *= -1;
	float mip_index = (pow((combo.g - 1.0), 3.0) + 1.0) * 8.0;//max(base_lod, specular_reflectance_and_roughness.w * env_roughness_scale * 9);
	//float mip_index = pow(rough, 1 / 2.2) * 8.0f;
	float4 reflectionMap = sampleCUBELOD(reflection_map, rVec, mip_index);
	float gloss = 1.0 - combo.g;
	fresnel = FresnelSchlickWithRoughness(specular_color, -view, normal, gloss);

	float3 reflection = reflectionMap.a * reflectionMap.rgb * EnvBRDFApprox(fresnel, combo.g, max(dot(normal, -view), 0.0)) * reflection_dif;

	//.. Finalize Output Color
    float4 out_color;
	out_color.a   = albedo.a;
	
	out_color.rgb = brdf + reflection;

	shader_data.common.selfIllumIntensity = 0;

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
