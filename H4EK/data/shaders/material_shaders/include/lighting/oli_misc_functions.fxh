//Amit's Code
float3 blend_rnm(float3 n1, float3 n2)
{
    float3 t = n1.xyz*float3( 2,  2, 2) + float3(-1, -1,  0);
    float3 u = n2.xyz*float3(-2, -2, 2) + float3( 1,  1, -1);
    float3 r = t*dot(t, u) - u*t.z;
    return normalize(r);
}

// Reoriented Normal Mapping
// http://blog.selfshadow.com/publications/blending-in-detail/
// Altered to take normals (-1 to 1 ranges) rather than unsigned normal maps (0 to 1 ranges)
float3 blend_rnm_signed(float3 n1, float3 n2)
{
    n1.z += 1;
    n2.xy = -n2.xy;

    return n1 * dot(n1, n2) / n1.z - n2;
}

float3 rnmBlendUnpacked(float3 n1, float3 n2)
{
    n1 += float3( 0,  0, 1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}


// from: https://iquilezles.org/articles/biplanar/
// The MIT License
// Copyright © 2015 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// How to do texture map a 3D object when it doesn't have 
// uv coordinates but can't afford full 3D solid texturing.

// The idea is to perform three planar texture projections 
// and blend the results based on the alignment of the
// normal vector to each one of the projection directions.

// The technique was invented by Mitch Prater in the early
// 90s, and has been called "Box mapping" or "Rounded cube
// mapping" traditionally, although more recently it has
// become popular in the realtime rendering community and
// rebranded as "triplanar" mapping.

// For a "biplanar" mapping example, visit:
//
// https://www.shadertoy.com/view/ws3Bzf



// "p" point apply texture to
// "n" normal at "p"
// "k" controls the sharpness of the blending in the transitions areas.
// "s" texture sampler
float4 triplanar_2d( in texture_sampler_2d s, in float4 transform, in float3 p, in float3 n, in float k)
{
    // project+fetch
    float4 x = sample2DGamma( s, transform_texcoord(p.yz, transform) );
	float4 y = sample2DGamma( s, transform_texcoord(p.zx, transform) );
	float4 z = sample2DGamma( s, transform_texcoord(p.xy, transform) );
    
    // and blend
    float3 m = pow( abs(n), float3(k, k, k) );
	return (x*m.x + y*m.y + z*m.z) / (m.x + m.y + m.z);
}

float3 triplanar_2d_normal( in texture_sampler_2d s, in float4 transform, in float3 p, in float3 n, in float k)
{
    // project+fetch
    float3 x = sample2DNormal( s, transform_texcoord(p.yz, transform) );
	float3 y = sample2DNormal( s, transform_texcoord(p.zx, transform) );
	float3 z = sample2DNormal( s, transform_texcoord(p.xy, transform) );
    
    float3 absVertNormal = abs(n);

    x = rnmBlendUnpacked(float3(n.zy, absVertNormal.x), x);
    y = rnmBlendUnpacked(float3(n.xz, absVertNormal.y), y);
    z = rnmBlendUnpacked(float3(n.xy, absVertNormal.z), z);

    // and blend
    float3 m = pow( abs(n), float3(k, k, k) );
	return (x*m.x + y*m.y + z*m.z) / (m.x + m.y + m.z);
}

// https://bgolus.medium.com/normal-mapping-for-a-triplanar-shader-10bf39dca05a
float4 world_space_triplanar_2d(texture_sampler_2d s, float4 xform, in float3 abs_world_position, in float3 world_normal)
{
    // calculate triplanar blend
    float3 triblend = saturate(pow(world_normal, 4));
    triblend /= max(dot(triblend, float3(1,1,1)), 0.0001);

    // preview blend
    // return fixed4(triblend.xyz, 1);

    // calculate triplanar uvs
    float2 uvX = abs_world_position.zy * xform.xy + xform.zw;
    float2 uvY = abs_world_position.xz * xform.xy + xform.zw;
    float2 uvZ = abs_world_position.xy * xform.xy + xform.zw;

    // offset UVs to prevent obvious mirroring
#if defined(TRIPLANAR_UV_OFFSET)
    uvY += 0.33;
    uvZ += 0.67;
#endif

    // minor optimization of sign(). prevents return value of 0
    float3 axisSign = world_normal < 0 ? -1 : 1;

    // flip UVs horizontally to correct for back side projection
#if defined(TRIPLANAR_CORRECT_PROJECTED_U)
    uvX.x *= axisSign.x;
    uvY.x *= axisSign.y;
    uvZ.x *= -axisSign.z;
#endif
    // sample textures
    float4 colX = sample2DGamma(s, uvX);
    float4 colY = sample2DGamma(s, uvY);
    float4 colZ = sample2DGamma(s, uvZ);
    float4 col = colX * triblend.x + colY * triblend.y + colZ * triblend.z;
    return col;
}

// https://bgolus.medium.com/normal-mapping-for-a-triplanar-shader-10bf39dca05a
float4 world_space_triplanar_2d_array(texture_sampler_2d_array s, float4 xform, in float3 abs_world_position, in float3 world_normal, in float array_index)
{
    // calculate triplanar blend
    float3 triblend = saturate(pow(world_normal, 4));
    triblend /= max(dot(triblend, float3(1,1,1)), 0.0001);

    // preview blend
    // return fixed4(triblend.xyz, 1);

    // calculate triplanar uvs
    float2 uvX = abs_world_position.zy * xform.xy + xform.zw;
    float2 uvY = abs_world_position.xz * xform.xy + xform.zw;
    float2 uvZ = abs_world_position.xy * xform.xy + xform.zw;

    // offset UVs to prevent obvious mirroring
#if defined(TRIPLANAR_UV_OFFSET)
    uvY += 0.33;
    uvZ += 0.67;
#endif

    // minor optimization of sign(). prevents return value of 0
    float3 axisSign = world_normal < 0 ? -1 : 1;

    // flip UVs horizontally to correct for back side projection
#if defined(TRIPLANAR_CORRECT_PROJECTED_U)
    uvX.x *= axisSign.x;
    uvY.x *= axisSign.y;
    uvZ.x *= -axisSign.z;
#endif
    // sample textures
    float4 colX = sample3DGamma(s, float3(uvX, array_index));
    float4 colY = sample3DGamma(s, float3(uvY, array_index));
    float4 colZ = sample3DGamma(s, float3(uvZ, array_index));
    float4 col = colX * triblend.x + colY * triblend.y + colZ * triblend.z;
    return col;
}

float3 world_space_triplanar_2d_array_normal(texture_sampler_2d_array s, float4 xform, in float3 abs_world_position, in float3 world_normal, in float array_index)
{
    // calculate triplanar blend
    float3 triblend = saturate(pow(world_normal, 4));
    triblend /= max(dot(triblend, float3(1,1,1)), 0.0001);

    // preview blend
    // return fixed4(triblend.xyz, 1);

    // calculate triplanar uvs
    // applying texture scale and offset values ala TRANSFORM_TEX macro
    float2 uvX = abs_world_position.zy * xform.xy + xform.zw;
    float2 uvY = abs_world_position.xz * xform.xy + xform.zw;
    float2 uvZ = abs_world_position.xy * xform.xy + xform.zw;

    // offset UVs to prevent obvious mirroring
#if defined(TRIPLANAR_UV_OFFSET)
    uvY += 0.33;
    uvZ += 0.67;
#endif

    // minor optimization of sign(). prevents return value of 0
    float3 axisSign = world_normal < 0 ? -1 : 1;

    // flip UVs horizontally to correct for back side projection
#if defined(TRIPLANAR_CORRECT_PROJECTED_U)
    uvX.x *= axisSign.x;
    uvY.x *= axisSign.y;
    uvZ.x *= -axisSign.z;
#endif
    // sample textures
    float3 tnormalX = sample3DNormal_approx(s, float3(uvX, array_index));
    float3 tnormalY = sample3DNormal_approx(s, float3(uvY, array_index));
    float3 tnormalZ = sample3DNormal_approx(s, float3(uvZ, array_index));

#if defined(TRIPLANAR_CORRECT_PROJECTED_U)
    tnormalX.x *= axisSign.x;
    tnormalY.x *= axisSign.y;
    tnormalZ.x *= -axisSign.z;
#endif
    float3 absVertNormal = abs(world_normal);

    // swizzle world normals to match tangent space and apply reoriented world_normal mapping blend
    tnormalX = rnmBlendUnpacked(float3(world_normal.zy, absVertNormal.x), tnormalX);
    tnormalY = rnmBlendUnpacked(float3(world_normal.xz, absVertNormal.y), tnormalY);
    tnormalZ = rnmBlendUnpacked(float3(world_normal.xy, absVertNormal.z), tnormalZ);

    // apply world space sign to tangent space Z
    tnormalX.z *= axisSign.x;
    tnormalY.z *= axisSign.y;
    tnormalZ.z *= axisSign.z;

    // sizzle tangent normals to match world world_normal and blend together
    float3 worldNormal = normalize(
        tnormalX.zyx * triblend.x +
        tnormalY.xzy * triblend.y +
        tnormalZ.xyz * triblend.z
    );

    // preview world normals
    // return fixed4(worldNormal * 0.5 + 0.5, 1);
    return worldNormal;
}

float3 world_space_triplanar_2d_normal(texture_sampler_2d s, float4 xform, in float3 abs_world_position, in float3 world_normal)
{
    // calculate triplanar blend
    float3 triblend = saturate(pow(world_normal, 4));
    triblend /= max(dot(triblend, float3(1,1,1)), 0.0001);

    // preview blend
    // return fixed4(triblend.xyz, 1);

    // calculate triplanar uvs
    // applying texture scale and offset values ala TRANSFORM_TEX macro
    float2 uvX = abs_world_position.zy * xform.xy + xform.zw;
    float2 uvY = abs_world_position.xz * xform.xy + xform.zw;
    float2 uvZ = abs_world_position.xy * xform.xy + xform.zw;

    // offset UVs to prevent obvious mirroring
#if defined(TRIPLANAR_UV_OFFSET)
    uvY += 0.33;
    uvZ += 0.67;
#endif

    // minor optimization of sign(). prevents return value of 0
    float3 axisSign = world_normal < 0 ? -1 : 1;

    // flip UVs horizontally to correct for back side projection
#if defined(TRIPLANAR_CORRECT_PROJECTED_U)
    uvX.x *= axisSign.x;
    uvY.x *= axisSign.y;
    uvZ.x *= -axisSign.z;
#endif
    // sample textures
    float3 tnormalX = sample2DNormal(s, uvX);
    float3 tnormalY = sample2DNormal(s, uvY);
    float3 tnormalZ = sample2DNormal(s, uvZ);

#if defined(TRIPLANAR_CORRECT_PROJECTED_U)
    tnormalX.x *= axisSign.x;
    tnormalY.x *= axisSign.y;
    tnormalZ.x *= -axisSign.z;
#endif
    float3 absVertNormal = abs(world_normal);

    // swizzle world normals to match tangent space and apply reoriented world_normal mapping blend
    tnormalX = rnmBlendUnpacked(float3(world_normal.zy, absVertNormal.x), tnormalX);
    tnormalY = rnmBlendUnpacked(float3(world_normal.xz, absVertNormal.y), tnormalY);
    tnormalZ = rnmBlendUnpacked(float3(world_normal.xy, absVertNormal.z), tnormalZ);

    // apply world space sign to tangent space Z
    tnormalX.z *= axisSign.x;
    tnormalY.z *= axisSign.y;
    tnormalZ.z *= axisSign.z;

    // sizzle tangent normals to match world world_normal and blend together
    float3 worldNormal = normalize(
        tnormalX.zyx * triblend.x +
        tnormalY.xzy * triblend.y +
        tnormalZ.xyz * triblend.z
    );

    // preview world normals
    // return fixed4(worldNormal * 0.5 + 0.5, 1);
    return worldNormal;
}
//End of Amits's code

float2 world_space_triplanar_2d_detnormal(texture_sampler_2d s, float4 xform, in float3 abs_world_position, in float3 world_normal)
{
    // calculate triplanar blend
    float3 triblend = saturate(pow(world_normal, 4));
    triblend /= max(dot(triblend, float3(1,1,1)), 0.0001);

    // preview blend
    // return fixed4(triblend.xyz, 1);

    // calculate triplanar uvs
    float2 uvX = abs_world_position.zy * xform.xy + xform.zw;
    float2 uvY = abs_world_position.xz * xform.xy + xform.zw;
    float2 uvZ = abs_world_position.xy * xform.xy + xform.zw;

    // offset UVs to prevent obvious mirroring
#if defined(TRIPLANAR_UV_OFFSET)
    uvY += 0.33;
    uvZ += 0.67;
#endif

    // minor optimization of sign(). prevents return value of 0
    float3 axisSign = world_normal < 0 ? -1 : 1;

    // flip UVs horizontally to correct for back side projection
#if defined(TRIPLANAR_CORRECT_PROJECTED_U)
    uvX.x *= axisSign.x;
    uvY.x *= axisSign.y;
    uvZ.x *= -axisSign.z;
#endif
    // sample textures
    float2 colX = sample2DVector(s, uvX);
    float2 colY = sample2DVector(s, uvY);
    float2 colZ = sample2DVector(s, uvZ);
    float2 col = colX * triblend.x + colY * triblend.y + colZ * triblend.z;
    return col;
}


float3 CompositeDetailNormalMapTriplanar(
	float3 baseNormal,
	texture_sampler_2d detailNormalSampler,
	float4 detailNormalXform,
	float detailNormalIntensity,
    float3 abs_world_position,
    float3 world_normal
    )
{
	float2 detailNormal = world_space_triplanar_2d_detnormal(detailNormalSampler, detailNormalXform, abs_world_position, world_normal);

	baseNormal.xy = baseNormal.xy + detailNormalIntensity * detailNormal.xy;
	baseNormal.z = sqrt(saturate(1.0f + dot(baseNormal.xy, -baseNormal.xy)));

	return baseNormal;
}

float4 albedo_colour_overlay(float4 base, float4 detail)
{
    float r = base.r < 0.5f ? 2 * base.r * detail.r : 1 - 2 * (1 - base.r) * (1 - detail.r);
    float g = base.g < 0.5f ? 2 * base.g * detail.g : 1 - 2 * (1 - base.g) * (1 - detail.g);
    float b = base.b < 0.5f ? 2 * base.b * detail.b : 1 - 2 * (1 - base.b) * (1 - detail.b);
    float a = base.a < 0.5f ? 2 * base.a * detail.a : 1 - 2 * (1 - base.a) * (1 - detail.a);
    return float4(r, g, b, a);
}

float3 calcChameleon(in float3 N, in float3 V, in float power[3], in float3 colours[3])
{
    float3 fresnel_color = 0;
    float fresnel  = 1-max(dot(N, V), _epsilon);
            
    float3  rim_fresnel = pow(fresnel, power[2] * 5);
    float3  mid_fresnel = pow(fresnel, power[1] * 5);
    float3  frt_fresnel = pow(1-fresnel, power[0] * 5);


    //rim_fresnel *= saturate(mid_fresnel + frt_fresnel);
    mid_fresnel *= 1-rim_fresnel;
    frt_fresnel *= 1-mid_fresnel;

    rim_fresnel *= colours[2];
    mid_fresnel *= colours[1];
    frt_fresnel *= colours[0];

    fresnel_color = color_screen(rim_fresnel, mid_fresnel);
    fresnel_color = color_screen(fresnel_color, frt_fresnel);

   return fresnel_color;
}
