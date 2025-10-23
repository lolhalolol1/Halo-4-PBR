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
