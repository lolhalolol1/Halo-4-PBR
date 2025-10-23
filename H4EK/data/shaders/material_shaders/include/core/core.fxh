#if !defined(__CORE_FXH)
#define __CORE_FXH

// define the platform before anything else
#if !defined(cgfx) && !defined(pc) && !defined(xenon)
#if defined(__CGC__)
#define cgfx
#elif !defined(_XBOX)
#define pc
#else
#define xenon
#endif
#endif

// Helpful define to detect when we're looking for CGFX include files
#if defined(cgfx) && !defined(__CGC__)
#define NOT_REALLY_CGFX
#endif


#if defined(cgfx)
#define STATIC_CONST static
#else
#define STATIC_CONST static const
#endif

// comment this line out to roll-back to original shading models
//#define APPLY_SQUARE_FALLOFF

// lighting modes
#define LM_DEFAULT 0
#define LM_PER_PIXEL 1
#define LM_PER_PIXEL_HR 2
#define LM_PER_PIXEL_ANALYTIC 3
#define LM_PER_PIXEL_ANALYTIC_HR 4
#define LM_PER_PIXEL_FLOATING_SHADOW 5
#define LM_PER_PIXEL_FORGE 6
#define LM_PROBE 7
#define LM_DYNAMIC_LIGHTING 8
#define LM_OBJECT 9
#define LM_ALBEDO 10
#define LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE 11
#define LM_PER_PIXEL_SIMPLE 12
#define LM_PROBE_AO 13

// shader pass
#define SP_DEFAULT 0
#define SP_ALBEDO 1
#define SP_STATIC_LIGHTING 2
#define SP_SINGLE_PASS_LIGHTING 3
#define SP_DYNAMIC_LIGHTING 4
#define SP_DECALS 5


// define some useful utility macros
#define BOOST_STRINGIZE(X)		BOOST_DO_STRINGIZE(X)
#define BOOST_DO_STRINGIZE(X)	#X
#define BOOST_JOIN(X,Y)			BOOST_DO_JOIN(X,Y)
#define BOOST_DO_JOIN(X,Y)		BOOST_DO_JOIN2(X,Y)
#define BOOST_DO_JOIN2(X,Y)		X##Y

#define pi 3.14159265358979323846

#define _epsilon 0.00001f
#define _1_minus_epsilon (1.0f - _epsilon)

#define bx2(x)		(((x) * 2) - 1)
#define bx2_inv(x)	(((x) * 0.5) + 0.5)

#if !defined(cgfx)
#define LOOP(func,output,data,static_count)					[unroll]for(int index=0;index<static_count;++index) func(output,data,index)
#define LOOP1(func,output,i1,data,static_count)				[unroll]for(int index=0;index<static_count;++index) func(output,i1,data,index)
#define LOOP2(func,output,i1,i2,data,static_count)			[unroll]for(int index=0;index<static_count;++index) func(output,i1,i2,data,index)
#define LOOP3(func,output,i1,i2,i3,data,static_count)		[unroll]for(int index=0;index<static_count;++index) func(output,i1,i2,i3,data,index)
#define LOOP3OUT2(func,output,output2,i1,i2,i3,data,static_count)		[unroll]for(int index=0;index<static_count;++index) func(output,output2,i1,i2,i3,data,index)
#define LOOP4(func,output,i1,i2,i3,i4,data,static_count)	[unroll]for(int index=0;index<static_count;++index) func(output,i1,i2,i3,i4,data,index)
#define LOOP5(func,output,i1,i2,i3,i4,i5,data,static_count)	[unroll]for(int index=0;index<static_count;++index) func(output,i1,i2,i3,i4,i5,data,index)
#else
#define LOOP(func,output,data,static_count)					for(int index=0;index<static_count;++index) func(output,data,index)
#define LOOP1(func,output,i1,data,static_count)				for(int index=0;index<static_count;++index) func(output,i1,data,index)
#define LOOP2(func,output,i1,i2,data,static_count)			for(int index=0;index<static_count;++index) func(output,i1,i2,data,index)
#define LOOP3(func,output,i1,i2,i3,data,static_count)		for(int index=0;index<static_count;++index) func(output,i1,i2,i3,data,index)
#define LOOP3OUT2(func,output,output2,i1,i2,i3,data,static_count)		for(int index=0;index<static_count;++index) func(output,output2,i1,i2,i3,data,index)
#define LOOP4(func,output,i1,i2,i3,i4,data,static_count)	for(int index=0;index<static_count;++index) func(output,i1,i2,i3,i4,data,index)
#define LOOP5(func,output,i1,i2,i3,i4,i5,data,static_count)	for(int index=0;index<static_count;++index) func(output,i1,i2,i3,i4,i5,data,index)
#endif

#if DX_VERSION == 9
#define power_2_0	1
#define power_2_1	(2 * power_2_0)
#define power_2_2	(2 * power_2_1)
#define power_2_3	(2 * power_2_2)
#define power_2_4	(2 * power_2_3)
#define power_2_5	(2 * power_2_4)
#define power_2_6	(2 * power_2_5)
#define power_2_7	(2 * power_2_6)
#define power_2_8	(2 * power_2_7)
#define power_2_9	(2 * power_2_8)
#define power_2_10	(2 * power_2_9)
#define power_2_11	(2 * power_2_10)
#define power_2_12	(2 * power_2_11)
#define power_2_13	(2 * power_2_12)
#define power_2_14	(2 * power_2_13)
#define power_2_15	(2 * power_2_14)
#define power_2_16	(2 * power_2_15)
#define power_2_17	(2 * power_2_16)
#define power_2_18	(2 * power_2_17)
#define power_2_19	(2 * power_2_18)
#define power_2_20	(2 * power_2_19)
#define power_2_21	(2 * power_2_20)
#define power_2_22	(2 * power_2_21)
#define TEST_BIT(flags, bit) (frac(flags / (2 * power_2_##bit)) - 0.5f >= 0.0f)
#define EXTRACT_BITS(bitfield, lo_bit, hi_bit) extract_bits(bitfield, power_2_##lo_bit, power_2_##hi_bit)
float extract_bits(float bitfield, int lo_power /*const power of 2*/, int hi_power /*const power of 2*/)
{
	float result = bitfield; // calling this an 'int' adds an unnecessary 'truncs'
	if (lo_power != power_2_0 /*2^0 compile time test*/)
	{
		// Should be 2 instructions: mad, floors
		result /= lo_power;
		result = floor(result);
	}
	if (hi_power != power_2_22 /*2^22 compile time test*/)
	{
		// Should be 3 instructions: mulsc, frcs, mulsc
		result /= (hi_power / lo_power);
		result = frac(result);
		result *= (hi_power / lo_power);
	}
	return result;
}
#elif DX_VERSION == 11
#define TEST_BIT(flags, bit) ((uint(flags) & (1<<bit)) != 0)
#define EXTRACT_BITS(flags, lo_bit, hi_bit) float((uint(flags) >> lo_bit) & ((1 << (hi_bit - lo_bit))-1))
#endif

#define MAKE_ACCUMULATING_LOOP(out_type, func, count)						\
void func(inout out_type output, const in s_common_shader_data common)		\
{																			\
	BOOST_JOIN(func,_initializer)(output,common);							\
	LOOP(BOOST_JOIN(func,_inner_loop),output,common,count);					\
}

#define MAKE_ACCUMULATING_LOOP_1(out_type, func, it1, count)				\
void func(inout out_type output, const in s_common_shader_data common, const in it1 i1)\
{																			\
	BOOST_JOIN(func,_initializer)(output,common,i1);						\
	LOOP1(BOOST_JOIN(func,_inner_loop),output,common,i1,count);				\
}

#define MAKE_ACCUMULATING_LOOP_2(out_type, func, it1, it2, count)			\
void func(inout out_type output, const in s_common_shader_data common, const in it1 i1, const in it1 i2)\
{																			\
	BOOST_JOIN(func,_initializer)(output,common,i1,i2);						\
	LOOP2(BOOST_JOIN(func,_inner_loop),output,common,i1,i2,count);			\
}

#define MAKE_ACCUMULATING_LOOP_3(out_type, func, it1, it2, it3, count)		\
void func(inout out_type output, const in s_common_shader_data common, const in it1 i1, const in it2 i2, const in it3 i3)\
{																			\
	BOOST_JOIN(func,_initializer)(output,common,i1,i2,i3);					\
	LOOP3(BOOST_JOIN(func,_inner_loop),output,common,i1,i2,i3,count);		\
}

#define MAKE_ACCUMULATING_LOOP_4(out_type, func, it1, it2, it3, it4, count)	\
void func(inout out_type output, const in s_common_shader_data common, const in it1 i1, const in it2 i2, const in it3 i3, const in it4 i4)\
{																			\
	BOOST_JOIN(func,_initializer)(output,common,i1,i2,i3,i4);				\
	LOOP4(BOOST_JOIN(func,_inner_loop),output,common,i1,i2,i3,i4,count);	\
}

#define MAKE_ACCUMULATING_LOOP_5(out_type, func, it1, it2, it3, it4, it5, count)\
void func(inout out_type output, const in s_common_shader_data common, const in it1 i1, const in it2 i2, const in it3 i3, const in it4 i4, const in it5 i5)\
{																			\
	BOOST_JOIN(func,_initializer)(output,common,i1,i2,i3,i4,i5);			\
	LOOP5(BOOST_JOIN(func,_inner_loop),output,common,i1,i2,i3,i4,i5,count);	\
}

#define MAKE_ACCUMULATING_LOOP_3_2OUT(out_type, out_type_2, func, it1, it2, it3, count)		\
void func(inout out_type output, inout out_type_2 output2, const in s_common_shader_data common, const in it1 i1, const in it2 i2, const in it3 i3)\
{																			\
	BOOST_JOIN(func,_initializer)(output, output2, common,i1,i2,i3);		\
	LOOP3OUT2(BOOST_JOIN(func,_inner_loop),output,output2,common,i1,i2,i3,count);		\
}

//
#if DX_VERSION == 9
#define SV_Target COLOR
#define SV_Target0 COLOR0
#define SV_Target1 COLOR1
#define SV_Target2 COLOR2
#define SV_Target3 COLOR3
#define SV_Depth DEPTH
#define SV_Depth0 DEPTH0
#define SV_Position POSITION
#define SV_Position0 POSITION0
#define SV_VertexID INDEX
#define SCREEN_POSITION_INPUT(_name) float2 _name : VPOS
#define BEGIN_TECHNIQUE technique
#define SET_VERTEX_SHADER(_func) VertexShader = compile vs_3_0 _func
#define SET_PIXEL_SHADER(_func) PixelShader = compile ps_3_0 _func
#elif DX_VERSION == 11
#define SCREEN_POSITION_INPUT(_name) float4 _name : SV_Position
#define BEGIN_TECHNIQUE technique11
#define SET_VERTEX_SHADER(_func) SetVertexShader(CompileShader(vs_5_0, _func))
#define SET_PIXEL_SHADER(_func) SetPixelShader(CompileShader(ps_5_0, _func))
#define SET_COMPUTE_SHADER(_func) SetComputeShader(CompileShader(cs_5_0, _func))
#endif

// include unique per-platform files
#include "core_cgfx.fxh"
#include "core_pc.fxh"
#include "core_xenon.fxh"

///////////////////////////////////////////////////////////////////////////////////////////////
// [hcoulby - 12.3.2010]
// Squared Falloff Trick for Analytic and VMF Lighting with a per-platform compensation term
//
// [tholmes - 04.5.2011]
// Added macro for Screen Space lights so they can mirror, and work right with this on/off
#if defined(APPLY_SQUARE_FALLOFF)
    //FALLOFF_COMPENSATION_DIRECT/_VMF defined in core_<platform>.fxh
    #define SQUARE_FALLOFF_DIRECT(x)(x *= x * FALLOFF_COMPENSATION_DIRECT)
    #define SQUARE_FALLOFF_VMF(x)  (x *= x * FALLOFF_COMPENSATION_VMF)
    #define SQUARE_FALLOFF_SS(x)  (x *= x * FALLOFF_COMPENSATION_DIRECT)
#else
	#define SQUARE_FALLOFF_DIRECT(x)
	#define SQUARE_FALLOFF_VMF(x)
	#define SQUARE_FALLOFF_SS(x)
#endif

// [tholmes - 04.5.2011]
// Included temporary bandwidth term which currently modulates intensities by 0.8
// Remove and/or change to 1.0 when bandwidth isn't being overridden or is gone
// This is used by direct/ss lights which we would like to be closer to vmf data
#define VMF_BANDWIDTH 1.0

///////////////////////////////////////////////////////////////////////////////////////////////


//
#include "core_types.fxh"

//
#include "core_functions.fxh"

//
#include "core_parameters.fxh"


///////////////////////////////////////////////////////////////////////////////////////////////
// Hack to ensure that the constant stepping include files are built into every material shader
#include "used_float.fxh"
#undef USER_PARAMETER_OFFSET
#undef USER_PARAMETER_SIZE
#undef USER_PARAMETER_NEXT
#undef USER_PARAMETER_CURRENT
#include "parameters/next_parameter.fxh"

#include "used_float2.fxh"
#undef USER_PARAMETER_OFFSET
#undef USER_PARAMETER_SIZE
#undef USER_PARAMETER_NEXT
#undef USER_PARAMETER_CURRENT
#include "parameters/next_parameter.fxh"

#include "used_float3.fxh"
#undef USER_PARAMETER_OFFSET
#undef USER_PARAMETER_SIZE
#undef USER_PARAMETER_NEXT
#undef USER_PARAMETER_CURRENT
#include "parameters/next_parameter.fxh"

#include "used_float4.fxh"
#undef USER_PARAMETER_OFFSET
#undef USER_PARAMETER_SIZE
#undef USER_PARAMETER_NEXT
#undef USER_PARAMETER_CURRENT
#include "parameters/next_parameter.fxh"



#endif 	// !defined(__CORE_FXH)