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
	float smooth = 1.05 * (1 - pow(1 - NdotL, 5)) * (1 - pow(1 - NdotV, 5));
	float single = lerp(smooth, rough, a) / pi;
	float multi = 0.1159 * a;
    return albedo * saturate((single + albedo * multi)) * light_irradiance * NdotL;
}

float3 fresnel_schlick(
    in float3 f0,
    in float cosTheta
    )
{
    return f0 + (1 - f0) * pow(1 - cosTheta, 5);
}
float3 fresnel_schlick_roughness(
    in float3 f0,
    in float cosTheta,
    in float gloss
    )
{
    return f0 + (max(gloss, f0) - f0) * pow(1 - cosTheta, 5);
}
float3 fresnel_lasagne(
    in float3 f0,
    in float3 f82,
    in float cosTheta
    )
{
    float3 a_lazanyi = 17.6513846 * (f0 - f82) + 8.16666667 * (1 - f0);
    return a_lazanyi * cosTheta * pow(1 - cosTheta, 6);
}

float ndf_aniso_ggx(
    in float NdotH,
    in float3 view_dir,
    in float3 H,
    in float3 tangent,
    in float3 binormal,
    in float at,
    in float ab
    )
{
    float TdotH = dot(tangent, H);
    float BdotH = dot(binormal, H);

    float a2 = at * ab;
    float3 v = float3(ab * TdotH, at * BdotH, a2 * NdotH);
    float v2 = saturate(dot(v, v));
    float w2 = a2 / v2;
    return a2 * w2 * w2 * (1.0 / pi);

    //return (numerator / denominator) * light_irradiance * NdotL;
}
float g_smith(
    in float NdotL,
    in float NdotV,
    in float a
    )
{
    float a2 = a * a;
    /*float g_1 = 2.0f * NdotV 
                / 
                (sqrt(a2 + (1 - a2) * (NdotV * NdotV)) + NdotV);*/

    float g_2 = 2 * NdotL * NdotV
                /
                max(NdotV * sqrt(a2 + (1 - a2) * (NdotL * NdotL)) + NdotL * sqrt(a2 + (1 - a2) * (NdotV * NdotV)), _epsilon);
    return g_2;
}

float G_aniso(
    in float NdotH,
    in float NdotL,
    in float NdotV,
    in float3 view_dir,
    in float3 light_dir,
    in float3 tangent,
    in float3 binormal,
    in float at,
    in float ab
    )
{
    float TdotV = dot(tangent, view_dir);
    float BdotV = dot(binormal, view_dir);
    float TdotL = dot(tangent, light_dir);
    float BdotL = dot(binormal, light_dir);

    float lambdaV = NdotL * length(float3(at * TdotV, ab * BdotV, NdotV));
    float lambdaL = NdotV * length(float3(at * TdotL, ab * BdotL, NdotL));
    return clamp(1.0f / (2.0 * (lambdaV + lambdaL)), 0.0f, 1.0f);
}

float ndf_ggx(
    in float NdotH,
    in float a2)
{
    float a2_squared = a2 * a2;
    float NDF_denom = max(NdotH * NdotH * (a2_squared - 1.0) + 1.0, _epsilon);
	return a2_squared / (pi * NDF_denom * NDF_denom);
}

void VMFDiffusePBR(
    const in s_vmf_sample_data vmfData,
    const in float3 normal,
    const in float3 geoNormal,
    const in float3 view_dir,
    const in float3 albedo,
    const in float roughness,
    const in float3 fresnel0,
    const in float3 fresnel1,
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

		const bool allowSharpen = (lightingMode != LM_PROBE && lightingMode != LM_PROBE_AO && lightingMode != LM_PER_PIXEL_FORGE);
	
		// We now store two linear SH probes
		// [adamgold 2/13/12] now knock out direct with the character shadow (as long as we're not in the sun)
		vmfDif0 = LinearSHEvaluate(vmfData, normal, geoNormal, 0, allowSharpen) * (albedo * (1 - fresnel0)) * lerp(shadowterm, 1.0f, floatingShadowAmount);
		vmfDif1 = LinearSHEvaluate(vmfData, normal, geoNormal, 1, allowSharpen) * (albedo * (1 - fresnel1));
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
    const in float3 f0,
    const in float4 f82,
    const in float4 material_parameters)
{
    //SH = 0.0f;
    float ao = brdf;
    brdf = 0.0f;

#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_VMF)
    float2 a2 = float2(material_parameters.x, 1 - ((1 - material_parameters.x) / 2));
    a2 *= a2;

    float3 view = normalize(common.view_dir_distance.xyz);
	float3 L[2] =   {
                    normalize(VMFGetVector(common.lighting_data.vmf_data, 0)),
					normalize(VMFGetVector(common.lighting_data.vmf_data, 1))
                    };
	float3 H[2] =   {
			        normalize(VMFGetVector(common.lighting_data.vmf_data, 0) - view),
			        normalize(VMFGetVector(common.lighting_data.vmf_data, 1) - view)
                    };
    float2 NdotH = float2(
			max(dot(H[0], common.normal), _epsilon),
			max(dot(H[1], common.normal), _epsilon));
    float NdotV = saturate(dot(-view, common.normal));
    float2 NdotL = float2(
            max(dot(L[0], common.normal), _epsilon),
            max(dot(L[1], common.normal), _epsilon));
    float2 VdotH = float2(
			max(dot(-view, H[0]), _epsilon),
			max(dot(-view, H[1]), _epsilon));

    float3 F[2] = 
    {
        fresnel_schlick(f0, VdotH.x),
        fresnel_schlick(f0, VdotH.y)
    };
#ifdef IRIDESCENT
    F[0] = lerp(F[0], saturate(F[0] - fresnel_lasagne(f0, f82.rgb, VdotH.x)), f82.w);
    F[1] = lerp(F[1], saturate(F[0] - fresnel_lasagne(f0, f82.rgb, VdotH.y)), f82.w);
#endif

#ifdef ANISO
    float aniso = material_parameters.w;
    float3 T, B;
    orthonormal_basis(common.normal, T, B);

    float2 aniso_rough_t = max(a2 * (1 - aniso), _epsilon);
    float2 aniso_rough_b = max(a2 * (1 + aniso), _epsilon);
    float2 NDF = float2(
                    ndf_aniso_ggx(NdotH.x, -view, H[0], T, B, aniso_rough_t.x, aniso_rough_b.x),
                    ndf_aniso_ggx(NdotH.y, -view, H[1], T, B, aniso_rough_t.y, aniso_rough_b.y));

    float2 aniso_g = float2(
                        G_aniso(NdotH.x, NdotL.x, NdotV, -view, L[0], T, B, aniso_rough_t.x, aniso_rough_b.x),
                        G_aniso(NdotH.y, NdotL.y, NdotV, -view, L[1], T, B, aniso_rough_t.x, aniso_rough_b.x));
    //float2 hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2.xx);
    float3 spec[2] = 
    {
        (F[0] * NDF.x * aniso_g.x) * NdotL.x * common.lighting_data.vmf_data.coefficients[1].xyz,
        (F[1] * NDF.y * aniso_g.y) * NdotL.y * common.lighting_data.vmf_data.coefficients[3].xyz
    }; 
    
#else
    float2 NDF = float2(
                        ndf_ggx(NdotH.x, a2.x),
                        ndf_ggx(NdotH.y, a2.y));

    float2 hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2.xx );

    float2 G = float2(
                    g_smith(NdotL.x, NdotV, a2.x),
                    g_smith(NdotL.y, NdotV, a2.x));
    float3 spec[2] = 
    {
        (F[0] * NDF.x / hammon_visibility.x) * NdotL.x * common.lighting_data.vmf_data.coefficients[1].xyz,
        (F[1] * NDF.y / hammon_visibility.y) * NdotL.y * common.lighting_data.vmf_data.coefficients[3].xyz
    }; 
#endif

    float3 albedo = common.albedo.xyz;
#ifdef CLEARCOAT
    float ccRough = material_parameters.y;
    float ccMask = material_parameters.z;
#endif

    float3 vmfDif0 = 0;
    float3 vmfDif1 = 0;

    VMFDiffusePBR(common.lighting_data.vmf_data, normal, common.geometricNormal, -common.view_dir_distance.xyz, albedo, 0.0, F[0], F[1], common.lighting_data.shadow_mask.g, common.lighting_data.savedAnalyticScalar, common.lighting_mode, vmfDif0, vmfDif1);

#ifdef CLEARCOAT
    float2 ccNdotH = float2(
			max(dot(H[0], normal), _epsilon),
			max(dot(H[1], normal), _epsilon));
    float ccNdotV = max(dot(-view, normal), _epsilon);
    float2 ccNdotL = float2(
            max(dot(L[0], normal), _epsilon),
            max(dot(L[1], normal), _epsilon));

    float2 cca2 = float2(ccRough, 1 - ((1 - ccRough) / 2));
    cca2 *= cca2;
    float3 ccF[2] = 
    {
        fresnel_schlick(0.04f, VdotH.x),
        fresnel_schlick(0.04f, VdotH.y)
    };
    float2 ccNDF = float2(
                    ndf_ggx(ccNdotH.x, cca2.x),
                    ndf_ggx(ccNdotH.x, cca2.y));

    float2 cc_hammon_visibility = 2 * lerp(2 * ccNdotL * ccNdotV, ccNdotL + ccNdotV, cca2.xx);

    float3 ccSpec[2] =
    {
        (ccF[0] * ccNDF.x / cc_hammon_visibility.x) * ccNdotL.x * common.lighting_data.vmf_data.coefficients[1].xyz * ccMask,
        (ccF[1] * ccNDF.y / cc_hammon_visibility.y) * ccNdotL.y * common.lighting_data.vmf_data.coefficients[3].xyz * ccMask
    };
    vmfDif0 *= (1 - (ccF[0]  * ccMask));
    vmfDif1 *= (1 - (ccF[1] * ccMask));
    spec[0] *= pow(1 - (ccF[0] * ccMask), 2);
    spec[1] *= pow(1 - (ccF[1] * ccMask), 2);
#endif
    
    float3 diffuse = vmfDif0 + vmfDif1;
        
    brdf += (spec[0] + spec[1]
#ifdef CLEARCOAT
        + ccSpec[0] + ccSpec[1]
#endif
        +
        (diffuse * (1 - common.shaderValues.y))) * ao;

    SH = CompSH(common, 0.0, common.normal);
    float3 fresnelNV = f0 + (1 - f0) * pow(1 - saturate(dot(normal, -view)), 5);     
    brdf += albedo * (1 - common.shaderValues.y) * (1 / pi) * SH * ao;
    SH += VMFDiffuse(common.lighting_data.vmf_data, common.normal, common.geometricNormal, common.lighting_data.shadow_mask.g, common.lighting_data.savedAnalyticScalar, common.lighting_mode) * ao;
#endif
}

void calc_pbr_inner_loop(
    inout float3 brdf,
    inout float3 SH,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float3 f0,
    const in float4 f82,
    const in float4 material_parameters,
    int index)
{
    float4 direction= common.lighting_data.light_direction_specular_scalar[index];
    float4 intensity_diffuse_scalar = common.lighting_data.light_intensity_diffuse_scalar[index];

    float3 albedo = common.albedo.xyz;
    float a2 = material_parameters.x * material_parameters.x;
    float3 view = normalize(common.view_dir_distance.xyz);
	float3 H = normalize(direction.xyz - view);
    float NdotH = max(dot(H, common.normal), _epsilon);
    float NdotV = max(dot(-view, common.normal), _epsilon);
    float NdotL = max(dot(direction.xyz, common.normal), _epsilon);
    float VdotH = max(dot(-view, H), _epsilon);
#ifdef CLEARCOAT
    float cca2 = material_parameters.y * material_parameters.y;
    float ccMask = material_parameters.z;
#endif
#ifdef ANISO
    float aniso = material_parameters.w;
    float3 T, B;
    orthonormal_basis(common.normal, T, B);
    float aniso_rough_t = max(a2 * (1 - aniso), _epsilon);
    float aniso_rough_b = max(a2 * (1 + aniso), _epsilon);
#endif

    float3 F = fresnel_schlick(f0, VdotH);

#ifdef IRIDESCENT
    F = lerp(F, saturate(F - fresnel_lasagne(f0, f82.rgb, VdotH)), f82.w);
#endif

#ifdef ANISO
    float NDF = ndf_aniso_ggx(NdotH, -view, H, T, B, aniso_rough_t, aniso_rough_b);
    float aniso_G = G_aniso(NdotH, NdotL, NdotV, -view, direction.xyz, T, B, aniso_rough_t, aniso_rough_b);

    //float hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2);
    float3 spec = (F * NDF * aniso_G) * NdotL * intensity_diffuse_scalar.xyz * direction.w;
#else
    float NDF = ndf_ggx(NdotH, a2);

    float hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2  * a2);

    float3 spec = (F * NDF / hammon_visibility) * NdotL * intensity_diffuse_scalar.xyz * direction.w;
#endif
    float3 diffuse = calc_hammon(common.normal, -view, direction.xyz, intensity_diffuse_scalar.xyz * direction.w, albedo, material_parameters.x);
#ifdef CLEARCOAT
    float3 ccF = fresnel_schlick(0.04f, VdotH);
    float ccNdotH = max(dot(H, normal), _epsilon);
    float ccNdotV = max(dot(-view, normal), _epsilon);
    float ccNdotL = max(dot(direction.xyz, normal), _epsilon);

    float ccNDF = ndf_ggx(ccNdotH, cca2);
    float cc_hammon_visibility = 2 * lerp(2 * ccNdotL * ccNdotV, ccNdotL + ccNdotV, cca2);
    float3 ccSpec = (ccF * ccNDF / cc_hammon_visibility) * ccNdotL * intensity_diffuse_scalar.xyz * direction.w * ccMask;
    
    diffuse *= (1 - (ccF * ccMask));
    spec *= pow(1 - (ccF * ccMask), 2);
    brdf += diffuse * (1 - common.shaderValues.y) + spec + ccSpec;
#else
    brdf += diffuse * (1 - common.shaderValues.y) + spec;
#endif
    SH += NdotL * intensity_diffuse_scalar.rgb * intensity_diffuse_scalar.a;
}

    MAKE_ACCUMULATING_LOOP_3_2OUTS(float3, float3, calc_pbr, float3, float3, float4, float4, MAX_LIGHTING_COMPONENTS);

#ifdef SKIN_BRDF
//adding calc_ggx back here so I can avoid changing VMFSkinPBR and srf_skin.fx to handle the BRDF in those place because I'm lazy :)
//Should do that later anyway for optimization.
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
    float a2 = a * a;
    F = fresnel_schlick(f0, VdotH);

    float NDF = ndf_ggx(NdotH, a2);

    float hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2);

    float3 numerator =  NDF * 
                        F;
    return (NDF * F / hammon_visibility) * light_irradiance * NdotL;
}

float3 VMFSkinPBR(
    inout float3 SH,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float3 f0,
    const in float4 material_parameters,
    const in float distortion,
    const in float power,
    const in float3 colour,
    const in texture_sampler_2d lut)
{
    float3 albedo = common.albedo.xyz;
    float3 fresnel0 = 0;
    float3 fresnel1 = 0;
    float3 view_dir = -common.view_dir_distance.xyz;

    float3 L[2] = 
    {
        VMFGetVector(common.lighting_data.vmf_data, 0),
        VMFGetVector(common.lighting_data.vmf_data, 1)
    };
//calculate specular


    float3 spec[2] =
    {
        spec[0] = calc_ggx(common.normal, view_dir, L[0], common.lighting_data.vmf_data.coefficients[1].xyz, f0.xyz, material_parameters.y, fresnel0) * material_parameters.x,
        spec[1] = calc_ggx(common.normal, view_dir, L[1], common.lighting_data.vmf_data.coefficients[3].xyz, f0.xyz, material_parameters.y, fresnel1) * material_parameters.x,
    };

    float3 vmfDif0, vmfDif1;

	if (common.lighting_mode == LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE || common.lighting_mode == LM_PER_PIXEL_SIMPLE)
	{
		// Just transfer the irradiance
		vmfDif0 = albedo * (1 / pi) * (1 - fresnel0) * common.lighting_data.vmf_data.coefficients[0].xyz;
        vmfDif1 = 0;
	}
	else
	{
	#if defined(xenon) || (DX_VERSION == 11)
		const float directLightingMinimumForShadows = ps_bsp_lightmap_scale_constants.y;
	#else
		const float directLightingMinimumForShadows = 0.3f;
	#endif
		float shadowterm = saturate(common.lighting_data.shadow_mask.g + directLightingMinimumForShadows);

		const bool allowSharpen = (common.lighting_mode != LM_PROBE && common.lighting_mode != LM_PROBE_AO && common.lighting_mode != LM_PER_PIXEL_FORGE);
	
		// We now store two linear SH probes
		// [adamgold 2/13/12] now knock out direct with the character shadow (as long as we're not in the sun)

        float NdotL_blur[2] =
        {
            dot(normal, L[0]),
            dot(normal, L[1])
        };

        float3 skin_dif[2] =
        {
            sample2D(lut, float2(mad(NdotL_blur[0], 0.5f, 0.5f), material_parameters.w)).xyz,
            sample2D(lut, float2(mad(NdotL_blur[1], 0.5f, 0.5f), material_parameters.w)).xyz
        };
        skin_dif[0] = float3(
			lerp(skin_dif[0].z, skin_dif[0].x, colour.x),
			lerp(skin_dif[0].y, skin_dif[0].x, colour.y),
			lerp(skin_dif[0].z, skin_dif[0].x, colour.z)
		) * 0.5f - 0.25f;
        skin_dif[1] = float3(
			lerp(skin_dif[1].z, skin_dif[1].x, colour.x),
			lerp(skin_dif[1].y, skin_dif[1].x, colour.y),
			lerp(skin_dif[1].z, skin_dif[1].x, colour.z)
		) * 0.5f - 0.25f;	

        float normalSmoothFactor[2] = 
        {
            saturate(1.0 - NdotL_blur[0]),
            saturate(1.0 - NdotL_blur[1])
        };
        normalSmoothFactor[0] *= normalSmoothFactor[0];
        normalSmoothFactor[1] *= normalSmoothFactor[1];

        float3 view_normalG[2] = 
        {
            /*normalize*/(lerp(common.normal, normal, 0.3 + 0.7 * normalSmoothFactor[0])),
            /*normalize*/(lerp(common.normal, normal, 0.3 + 0.7 * normalSmoothFactor[1]))
        };

        float3 view_normalB[2] = 
        {
            /*normalize*/(lerp(common.normal, normal, normalSmoothFactor[0])),
            /*normalize*/(lerp(common.normal, normal, normalSmoothFactor[1]))
        };

        float NoL_ShadeG[2] = 
        {
            saturate(dot(view_normalG[0], L[0])),
            saturate(dot(view_normalG[1], L[1]))
        };
        
        float NoL_ShadeB[2] = 
        {
            saturate(dot(view_normalB[0], L[0])),
            saturate(dot(view_normalB[1], L[1]))
        };
        
        float3 rgbNdotL[2] = 
        {
            float3(saturate(NdotL_blur[0]), NoL_ShadeG[0], NoL_ShadeB[0]),
            float3(saturate(NdotL_blur[1]), NoL_ShadeG[1], NoL_ShadeB[1]),
        };
        skin_dif[0] = saturate(skin_dif[0] + rgbNdotL[0]);
        skin_dif[1] = saturate(skin_dif[1] + rgbNdotL[1]);

		vmfDif0 = skin_dif[0] * (albedo / pi) * (1 - fresnel0) * material_parameters.x * common.lighting_data.vmf_data.coefficients[1].xyz * lerp(shadowterm, 1.0f, common.lighting_data.savedAnalyticScalar);
		vmfDif1 = skin_dif[1] * (albedo / pi) * (1 - fresnel1) * material_parameters.x * common.lighting_data.vmf_data.coefficients[3].xyz;
	}

    SH = CompSH(common, 0.0, common.normal);
    float3 brdf = albedo * (1 / pi) * SH * material_parameters.x;
    brdf += (vmfDif0 + vmfDif1 + spec[0] + spec[1]);

    return brdf;
}
#endif

#ifdef H2A_MATERIAL
void calc_pbr_h2a_initializer(
    inout float3 brdf,
    inout float3 SH,
    const in s_common_shader_data common,
    const in float3 f0,
    const in float3 ccf0,
    const in float4 material_parameters)
{
    //SH = 0.0f;
    float ao = brdf;
    brdf = 0.0f;

#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_VMF)
    float2 a2 = float2(material_parameters.x, 1 - ((1 - material_parameters.x) / 2));
    a2 *= a2;

    float3 view = normalize(common.view_dir_distance.xyz);
	float3 L[2] =   {
                    normalize(VMFGetVector(common.lighting_data.vmf_data, 0)),
					normalize(VMFGetVector(common.lighting_data.vmf_data, 1))
                    };
	float3 H[2] =   {
			        normalize(VMFGetVector(common.lighting_data.vmf_data, 0) - view),
			        normalize(VMFGetVector(common.lighting_data.vmf_data, 1) - view)
                    };
    float2 NdotH = float2(
			max(dot(H[0], common.normal), _epsilon),
			max(dot(H[1], common.normal), _epsilon));
    float NdotV = saturate(dot(-view, common.normal));
    float2 NdotL = float2(
            max(dot(L[0], common.normal), _epsilon),
            max(dot(L[1], common.normal), _epsilon));
    float2 VdotH = float2(
			max(dot(-view, H[0]), _epsilon),
			max(dot(-view, H[1]), _epsilon));

    float3 F[2] = 
    {
        fresnel_schlick(f0, VdotH.x),
        fresnel_schlick(f0, VdotH.y)
    };

#ifdef ANISO
    float aniso = material_parameters.w;
    float3 T, B;
    orthonormal_basis(common.normal, T, B);

    float2 aniso_rough_t = max(a2 * (1 - aniso), _epsilon);
    float2 aniso_rough_b = max(a2 * (1 + aniso), _epsilon);
    float2 NDF = float2(
                    ndf_aniso_ggx(NdotH.x, -view, H[0], T, B, aniso_rough_t.x, aniso_rough_b.x),
                    ndf_aniso_ggx(NdotH.y, -view, H[1], T, B, aniso_rough_t.y, aniso_rough_b.y));

    float2 aniso_g = float2(
                        G_aniso(NdotH.x, NdotL.x, NdotV, -view, L[0], T, B, aniso_rough_t.x, aniso_rough_b.x),
                        G_aniso(NdotH.y, NdotL.y, NdotV, -view, L[1], T, B, aniso_rough_t.x, aniso_rough_b.x));
    //float2 hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2.xx);
    float3 spec[2] = 
    {
        (F[0] * NDF.x * aniso_g.x) * NdotL.x * common.lighting_data.vmf_data.coefficients[1].xyz,
        (F[1] * NDF.y * aniso_g.y) * NdotL.y * common.lighting_data.vmf_data.coefficients[3].xyz
    }; 
    
#else
    float2 NDF = float2(
                        ndf_ggx(NdotH.x, a2.x),
                        ndf_ggx(NdotH.y, a2.y));

    float2 hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2.xx );

    float2 G = float2(
                    g_smith(NdotL.x, NdotV, a2.x),
                    g_smith(NdotL.y, NdotV, a2.x));
    float3 spec[2] = 
    {
        (F[0] * NDF.x / hammon_visibility.x) * NdotL.x * common.lighting_data.vmf_data.coefficients[1].xyz,
        (F[1] * NDF.y / hammon_visibility.y) * NdotL.y * common.lighting_data.vmf_data.coefficients[3].xyz
    }; 
#endif

    float3 albedo = common.albedo.xyz;
#ifdef CLEARCOAT
    float ccRough = material_parameters.y;
    float ccMask = material_parameters.z;
#endif

    float3 vmfDif0 = 0;
    float3 vmfDif1 = 0;

    VMFDiffusePBR(common.lighting_data.vmf_data, common.normal, common.geometricNormal, -common.view_dir_distance.xyz, albedo, 0.0, F[0], F[1], common.lighting_data.shadow_mask.g, common.lighting_data.savedAnalyticScalar, common.lighting_mode, vmfDif0, vmfDif1);

#ifdef CLEARCOAT
    float2 cca2 = float2(ccRough, 1 - ((1 - ccRough) / 2));
    cca2 *= cca2;
    float3 ccF[2] = 
    {
        fresnel_schlick(ccf0, VdotH.x),
        fresnel_schlick(ccf0, VdotH.y)
    };
    float2 ccNDF = float2(
                    ndf_ggx(NdotH.x, a2.x),
                    ndf_ggx(NdotH.x, a2.y));

    float2 cc_hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, cca2.xx);

    float3 ccSpec[2] =
    {
        (ccF[0] * ccNDF.x / cc_hammon_visibility.x) * NdotL.x * common.lighting_data.vmf_data.coefficients[1].xyz * ccMask,
        (ccF[1] * ccNDF.y / cc_hammon_visibility.y) * NdotL.y * common.lighting_data.vmf_data.coefficients[3].xyz * ccMask
    };
    vmfDif0 *= (1 - (ccF[0]  * ccMask));
    vmfDif1 *= (1 - (ccF[1] * ccMask));
    spec[0] *= pow(1 - (ccF[0] * ccMask), 2);
    spec[1] *= pow(1 - (ccF[1] * ccMask), 2);
#endif
    
    float3 diffuse = vmfDif0 + vmfDif1;
        
    brdf += (spec[0] + spec[1]
#ifdef CLEARCOAT
        + ccSpec[0] + ccSpec[1]
#endif
        +
        (diffuse * (1 - common.shaderValues.y))) * ao;

    SH = CompSH(common, 0.0, common.normal);
    float3 fresnelNV = f0 + (1 - f0) * pow(1 - saturate(dot(common.normal, -view)), 5);
    brdf += albedo * (1 - common.shaderValues.y) * (1 / pi) * SH * ao;
    SH += VMFDiffuse(common.lighting_data.vmf_data, common.normal, common.geometricNormal, common.lighting_data.shadow_mask.g, common.lighting_data.savedAnalyticScalar, common.lighting_mode) * ao;
#endif
}

void calc_pbr_h2a_inner_loop(
    inout float3 brdf,
    inout float3 SH,
    const in s_common_shader_data common,
    const in float3 f0,
    const in float3 ccf0,
    const in float4 material_parameters,
    int index)
{
    float4 direction= common.lighting_data.light_direction_specular_scalar[index];
    float4 intensity_diffuse_scalar = common.lighting_data.light_intensity_diffuse_scalar[index];

    float3 albedo = common.albedo.xyz;
    float a2 = material_parameters.x * material_parameters.x;
    float3 view = normalize(common.view_dir_distance.xyz);
	float3 H = normalize(direction.xyz - view);
    float NdotH = max(dot(H, common.normal), _epsilon);
    float NdotV = max(dot(-view, common.normal), _epsilon);
    float NdotL = max(dot(direction.xyz, common.normal), _epsilon);
    float VdotH = max(dot(-view, H), _epsilon);
#ifdef CLEARCOAT
    float cca2 = material_parameters.y * material_parameters.y;
    float ccMask = material_parameters.z;
#endif
#ifdef ANISO
    float aniso = material_parameters.w;
    float3 T, B;
    orthonormal_basis(common.normal, T, B);
    float aniso_rough_t = max(a2 * (1 - aniso), _epsilon);
    float aniso_rough_b = max(a2 * (1 + aniso), _epsilon);
#endif

    float3 F = fresnel_schlick(f0, VdotH);

#ifdef ANISO
    float NDF = ndf_aniso_ggx(NdotH, -view, H, T, B, aniso_rough_t, aniso_rough_b);
    float aniso_G = G_aniso(NdotH, NdotL, NdotV, -view, direction.xyz, T, B, aniso_rough_t, aniso_rough_b);

    //float hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2);
    float3 spec = (F * NDF * aniso_G) * NdotL * intensity_diffuse_scalar.xyz * direction.w;
#else
    float NDF = ndf_ggx(NdotH, a2);

    float hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, a2  * a2);

    float3 spec = (F * NDF / hammon_visibility) * NdotL * intensity_diffuse_scalar.xyz * direction.w;
#endif
    float3 diffuse = calc_hammon(common.normal, -view, direction.xyz, intensity_diffuse_scalar.xyz * direction.w, albedo, material_parameters.x);
#ifdef CLEARCOAT
    float3 ccF = fresnel_schlick(ccf0, VdotH);

    float ccNDF = ndf_ggx(NdotH, cca2);
    float cc_hammon_visibility = 2 * lerp(2 * NdotL * NdotV, NdotL + NdotV, cca2);
    float3 ccSpec = (ccF * ccNDF / cc_hammon_visibility) * NdotL * intensity_diffuse_scalar.xyz * direction.w * ccMask;
    
    diffuse *= (1 - (ccF * ccMask));
    spec *= pow(1 - (ccF * ccMask), 2);
    brdf += diffuse * (1 - common.shaderValues.y) + spec + ccSpec;
#else
    brdf += diffuse * (1 - common.shaderValues.y) + spec;
#endif
    SH += NdotL * intensity_diffuse_scalar.rgb * intensity_diffuse_scalar.a;
}

    MAKE_ACCUMULATING_LOOP_3_2OUT(float3, float3, calc_pbr_h2a, float3, float3, float4, MAX_LIGHTING_COMPONENTS);

#endif

#endif