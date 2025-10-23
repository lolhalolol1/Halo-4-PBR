#if !defined(__LIGHTING_MODELS_REBORN_FXH)
#define __LIGHTING_MODELS_REBORN_FXH

#include "core/core_types.fxh"
#include "lighting/vmf.fxh"
#include "lighting/sh.fxh"
//#include "lighting/brdf_resources.fxh"

void orthonormal_basis(in float3 normal, out float3 T, out float3 B)
{
    float3 f,r;
    if(normal.z < -0.999999)
    {
        T = float3(0 , -1, 0);
        B = float3(-1, 0, 0);
    }
    else
    {
        float a = 1./(1. + normal.z);
        float b = -normal.x * normal.y * a;
        T = normalize(float3(1.0 - normal.x * normal.x * a, b, -normal.x));
        B = normalize(float3(b, 1.0 - normal.y * normal.y * a, -normal.y));
    }
    //return( float3x3(u,v,n) );
}

float3 FresnelSchlick(float3 SpecularColor, float3 E,float3 H)
{
	return SpecularColor + (1.0 - SpecularColor) * pow(1.0 - clamp(dot(E, H), 0.0001, 1), 5.0);
}
float3 FresnelSchlickWithRoughness(float3 SpecularColor, float3 E, float3 N, float Gloss)
{
    return SpecularColor + (max(Gloss, SpecularColor) - SpecularColor) * pow(1 - saturate(dot(E, N)), 5);
}

float3 calc_hammon(
    in float3 normal_dir,
    in float3 view_dir,
    in float3 light_dir,
    in float3 light_irradiance,
    in float3 albedo,
    in float  a
    )
{
    float3 H = normalize(light_dir + view_dir);
	
    float NdotL = max(dot(normal_dir, light_dir), 0.0); 
	float NdotH = max(dot(normal_dir, H), 0.0); 
	float NdotV = max(dot(normal_dir, view_dir), 0.0);
	float LdotV = max(dot(light_dir, view_dir), 0.0);

    float facing = 0.5 + 0.5 * LdotV;
	float rough = facing * (0.9 - 0.4 * facing) * ((0.5 + NdotH) / max(NdotH, _epsilon));
	float smooth = 1.05 * 0.96 * (1 - pow(1 - NdotL, 5)) * (1 - pow(1 - NdotV, 5));
	float single = (1 / pi) * lerp(smooth, rough, a);
	float multi = 0.1159 * a;
    return albedo * saturate((single + albedo * multi)) * light_irradiance * NdotL;
}

float3 calc_ggx(
    in float3 normal_dir,
    in float3 view_dir,
    in float3 light_dir,
    in float3 light_irradiance,
    in float3 f0,
    in float a,
    inout float3 F
    )
{
    float3 H    = normalize(light_dir + view_dir);
    float NdotL = clamp(dot(normal_dir, light_dir), 0.0001, 1.0);
	float NdotV = clamp(dot(normal_dir, view_dir), 0.0001, 1.0);
    float LdotH = clamp(dot(light_dir, H), 0.0001, 1.0);
	float VdotH = clamp(dot(view_dir, H), 0.0001, 1.0);
    float NdotH = clamp(dot(normal_dir, H), 0.0001, 1.0);

    float a2_sqrd = pow(a, 4);
    F = f0 + (1 - f0) * pow(1.0f - VdotH, 5);

    float NDFdenom = max((NdotH * a2_sqrd - NdotH) * NdotH + 1.0, 0.0001);
    float NDF = a2_sqrd / (pi * NDFdenom * NDFdenom);

  float L = 2.0 * NdotL / (NdotL + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotL * NdotL)));
	float V = 2.0 * NdotV / (NdotV + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotV * NdotV)));
    float G = L * V;
    
    float3 numerator =  NDF * 
                        G * 
                        F;
    float3 denominator  = max(4.0 * NdotV * NdotL, 0.0001);

    return (numerator / denominator) * light_irradiance * NdotL;
}

float3 calc_ggx_aniso(
    in float3 normal_dir,
    in float3 view_dir,
    in float3 light_dir,
    in float3 light_irradiance,
    in float3 f0,
    in float3 tangent,
    in float3 binormal,
    in float a,
    in float at,
    in float ab,
    inout float3 F
    )
{
    float3 H    = normalize(light_dir + view_dir);
    float NdotL = clamp(dot(normal_dir, light_dir), 0.0001, 1.0);
	float NdotV = clamp(dot(normal_dir, view_dir), 0.0001, 1.0);
    float LdotH = clamp(dot(light_dir, H), 0.0001, 1.0);
	float VdotH = clamp(dot(view_dir, H), 0.0001, 1.0);
    float NdotH = clamp(dot(normal_dir, H), 0.0001, 1.0);

    float a2_sqrd = pow(a, 4);
    F = f0 + (1 - f0) * pow(1.0f - VdotH, 5);

    float TdotH = dot(tangent, H);
    float BdotH = dot(binormal, H);
    float TdotV = dot(tangent, view_dir);
    float BdotV = dot(tangent, view_dir);
    float TdotL = dot(tangent, view_dir);
    float BdotL = dot(tangent, view_dir);

    float a2 = at * ab;
    float3 v = float3(ab * TdotH, at * BdotH, a2 * NdotH);
    float v2 = saturate(dot(v, v));
    float w2 = a2 / v2;
    float NDF_aniso = a2 * w2 * w2 * (1.0 / pi);

    /*float L = 2.0 * NdotL / (NdotL + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotL * NdotL)));
	float V = 2.0 * NdotV / (NdotV + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotV * NdotV)));
    float G = L * V;*/

    float lambdaV = NdotL * length(float3(at * TdotV, ab * BdotV, NdotV));
    float lambdaL = NdotV * length(float3(at * TdotL, ab * BdotL, NdotL));
    float G = clamp(0.5f / (lambdaV + lambdaL), 0.0f, 1.0f);
    
    
    float3 numerator    = NDF_aniso * 
                          G * 
                          F;
    //float3 denominator  = max(4.0 * NdotV * NdotL, 0.0001);

    return (numerator /* denominator*/) * light_irradiance * NdotL;
}

void VMFDiffusePBR(
    const in s_vmf_sample_data vmfData,
    const in float3 normal,
    const in float3 view_dir,
    const in float3 albedo,
    const in float roughness,
    const in float3 fresnel0,
	const in float characterShadow,
	const in float floatingShadowAmount,
	const in int lightingMode,
    inout float3 vmfDif0,
    inout float3 vmfDif1)
{
	if (lightingMode == LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE || lightingMode == LM_PER_PIXEL_SIMPLE)
	{
		// Just transfer the irradiance
		vmfDif0 = albedo * (1 / pi) * (1 - fresnel0) * vmfData.coefficients[0].xyz;
        vmfDif1 = 0;
	}
	else
	{
	#if defined(xenon) || (DX_VERSION == 11)
		const float directLightingMinimumForShadows = ps_bsp_lightmap_scale_constants.y;
	#else
		const float directLightingMinimumForShadows = 0.3f;
	#endif
		float shadowterm = saturate(characterShadow + directLightingMinimumForShadows);

		//const bool allowSharpen = (lightingMode != LM_PROBE && lightingMode != LM_PROBE_AO && lightingMode != LM_PER_PIXEL_FORGE);
	
		// We now store two linear SH probes
		// [adamgold 2/13/12] now knock out direct with the character shadow (as long as we're not in the sun)
		//vmfDif0 = LinearSHEvaluate(vmfData, normal, geoNormal, 0, allowSharpen) * (albedo * (1 - fresnel0)) * lerp(shadowterm, 1.0f, floatingShadowAmount);
		//vmfDif1 = LinearSHEvaluate(vmfData, normal, geoNormal, 1, allowSharpen) * (albedo * (1 - fresnel1));

        vmfDif0 = calc_hammon(normal, view_dir, VMFGetVector(vmfData, 0), vmfData.coefficients[1].xyz, albedo, roughness) * lerp(shadowterm, 1.0f, floatingShadowAmount);
		vmfDif1 = calc_hammon(normal, view_dir, VMFGetVector(vmfData, 1), vmfData.coefficients[3].xyz, albedo, roughness);
	}
}

float3 EnvBRDFApprox(float3 SpecularColor, float Roughness, float NoV )
{
	const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
	float4 r = Roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	float2 AB = float2( -1.04, 1.04 ) * a004 + r.zw;
	return SpecularColor * AB.x + AB.y;
}

void calc_pbr_initializer(
    inout float3 brdf,
    inout float3 SH,
    const in s_common_shader_data common,
    const in float3 normal,
#ifdef CLEARCOAT
    const in float4 f0,
#else
    const in float3 f0,
#endif
    const in float rough)
{

    //SH = 0.0f;
    float ao = brdf;
    brdf = 0.0f;

#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_VMF)
	float3 viewDir = common.view_dir_distance.xyz;
	float3 albedo = common.albedo.xyz;
    #ifdef CLEARCOAT
        float ccRough = f0.w;
    #endif
    #ifdef ANISO
        float3 T, B;
        orthonormal_basis(normal, T, B);

        //float3 Tangent = common.tangent_frame[2];
        float aniso_rough_t = max(rough * rough * (1 - 0.3), _epsilon);
        float aniso_rough_b = max(rough * rough * (1 + 0.3), _epsilon);
    #endif
	//if (common.lighting_mode != LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE && common.lighting_mode != LM_PER_PIXEL_SIMPLE)
	{
        #if defined(xenon) || (DX_VERSION == 11)
            const float directLightingMinimumForShadows = ps_bsp_lightmap_scale_constants.y;
        #else
		    const float directLightingMinimumForShadows = 0.3f;
	    #endif

        float shadowterm = saturate(common.lighting_data.shadow_mask.g + directLightingMinimumForShadows);

		float3 viewDir = common.view_dir_distance.xyz;

        float NdotV = clamp(dot(-viewDir, normal), 0.0001, 1);
		float NdotVs = clamp(dot(-common.view_dir_distance.xyz, normal), 0.0001, 1);

		float3 fresnel0 = 0;
		float3 fresnel1 = 0;
        #ifdef ANISO
            float3 spec[2] =    
                            {
                                calc_ggx_aniso(normal, -common.view_dir_distance.xyz, VMFGetVector(common.lighting_data.vmf_data, 0), common.lighting_data.vmf_data.coefficients[1].xyz, f0.xyz, T, B, rough, aniso_rough_t, aniso_rough_b, fresnel0),
                                calc_ggx_aniso(normal, -common.view_dir_distance.xyz, VMFGetVector(common.lighting_data.vmf_data, 1), common.lighting_data.vmf_data.coefficients[3].xyz, f0.xyz, T, B, rough, aniso_rough_t, aniso_rough_b, fresnel1)
                            };
        #else
            float3 spec[2] =    
                {
                    spec[0] = calc_ggx(normal, -common.view_dir_distance.xyz, VMFGetVector(common.lighting_data.vmf_data, 0), common.lighting_data.vmf_data.coefficients[1].xyz, f0.xyz, rough, fresnel0),
                    spec[1] = calc_ggx(normal, -common.view_dir_distance.xyz, VMFGetVector(common.lighting_data.vmf_data, 1), common.lighting_data.vmf_data.coefficients[3].xyz, f0.xyz, rough, fresnel1)
                };
        #endif

        float3 vmfDif0;
        float3 vmfDif1;
        VMFDiffusePBR(common.lighting_data.vmf_data, normal, -common.view_dir_distance.xyz, albedo, rough, fresnel0, common.lighting_data.shadow_mask.g, common.lighting_data.savedAnalyticScalar, common.lighting_mode, vmfDif0, vmfDif1);

        #ifdef CLEARCOAT
            float3 ccFr0 = 0;
            float3 ccFr1 = 0;
            float3 ccSpec[2] =
            {
                calc_ggx(normal, -common.view_dir_distance.xyz, VMFGetVector(common.lighting_data.vmf_data, 0), common.lighting_data.vmf_data.coefficients[1].xyz, (float3)0.04f, ccRough, ccFr0) /* eccclobe*/,
                calc_ggx(normal, -common.view_dir_distance.xyz, VMFGetVector(common.lighting_data.vmf_data, 1), common.lighting_data.vmf_data.coefficients[3].xyz, (float3)0.04f, ccRough, ccFr1) /* eccclobe*/
            };
            vmfDif0 *= (1 - ccFr0);
            vmfDif1 *= (1 - ccFr1);
            spec[0] *= pow(1 - ccFr0, 2);
            spec[1] *= pow(1 - ccFr1, 2);
        #endif
        float3 diffuse = vmfDif0 + vmfDif1;
        
        brdf += (spec[0] + spec[1]
            #ifdef CLEARCOAT
                + ccSpec[0] + ccSpec[1]
            #endif
                +
                (diffuse * (1 - common.shaderValues.y))) * ao;
	}

        SH = CompSH(common, 0.0, ao, normal);
        brdf += (albedo * (1 - common.shaderValues.y)) * SH;     
        SH += VMFDiffuse(common.lighting_data.vmf_data, normal, common.geometricNormal, common.lighting_data.shadow_mask.g, common.lighting_data.savedAnalyticScalar, common.lighting_mode) * ao;
    #endif
}

void calc_pbr_inner_loop(
    inout float3 brdf,
    inout float3 SH,
    const in s_common_shader_data common,
    const in float3 normal,
#ifdef CLEARCOAT
    const in float4 f0,
#else
    const in float3 f0,
#endif
    const in float rough,
    int index)
{
    float4 direction= common.lighting_data.light_direction_specular_scalar[index];
    float4 intensity_diffuse_scalar = common.lighting_data.light_intensity_diffuse_scalar[index];
    float3 V = common.view_dir_distance.xyz;
    #ifdef CLEARCOAT
        float ccRough = f0.w;
    #endif
    #ifdef ANISO
        float3 T, B;
        orthonormal_basis(normal, T, B);
        float aniso_rough_t = max(rough * rough * (1 - 0.3), _epsilon);
        float aniso_rough_b = max(rough * rough * (1 + 0.3), _epsilon);
    #endif

    float3 albedo = common.albedo.rgb;
	float3 fresnel = 0;

#ifdef ANISO
    float3 spec = calc_ggx_aniso(normal, -V, direction, intensity_diffuse_scalar.xyz * intensity_diffuse_scalar.w, f0.xyz, T, B, rough, aniso_rough_t, aniso_rough_b, fresnel);
#else
	float3 spec = calc_ggx(normal, -V, direction, intensity_diffuse_scalar.xyz * intensity_diffuse_scalar.w, f0.xyz, rough, fresnel);
#endif
    float3 diffuse = calc_hammon(normal, -V, direction, intensity_diffuse_scalar.xyz * intensity_diffuse_scalar.w, albedo, rough);
    #ifdef CLEARCOAT
        float3 ccFr = 0;
        float3 ccSpec = calc_ggx(normal, -V, direction, intensity_diffuse_scalar.xyz * intensity_diffuse_scalar.w, (float3)0.04f, ccRough, ccFr) /* eccclobe*/;
        diffuse *= (1 - ccFr);
        spec *= pow(1 - ccFr, 2);
    #endif
    #ifdef CLEARCOAT
        brdf += diffuse * (1 - common.shaderValues.y) + spec + ccSpec;
    #else
        brdf += diffuse * (1 - common.shaderValues.y) + spec;
    #endif
}

#ifdef CLEARCOAT
    MAKE_ACCUMULATING_LOOP_3_2OUT(float3, float3, calc_pbr, float3, float4, float, MAX_LIGHTING_COMPONENTS);
#else
    MAKE_ACCUMULATING_LOOP_3_2OUT(float3, float3, calc_pbr, float3, float3, float, MAX_LIGHTING_COMPONENTS);
#endif

#endif