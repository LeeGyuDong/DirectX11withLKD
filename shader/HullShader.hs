////////////////////////////////////////////
// FileName : BasicTessellation.hs
////////////////////////////////////////////

/////////////
// structure
/////////////
struct HullInputType
{
	float4 position : POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
	float3 binormal : BINORMAL;
	float3 viewRay : TEXCOORD1;
	float4 worldPosition : TEXCOORD2;
	float4 localPosition : TEXCOORD3;
	uint RTlndex : SV_RenderTargetArrayIndex;
	float tessFactor : TESS;
};


struct PatchTess
{
	float EdgeTess[3] : SV_TessFactor;
	float InsideTess : SV_InsideTessFactor;
};

struct HullOut
{
	float4 position : POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
	float3 binormal : BINORMAL;
	float3 viewRay : TEXCOORD1;
	float4 worldPosition : TEXCOORD2;
	float4 localPosition : TEXCOORD3;
	uint RTlndex : SV_RenderTargetArrayIndex;
};

///////////////////////
// ConstHull Shader
///////////////////////
PatchTess BasicTessellationConstHullShader(InputPatch<HullInputType, 3> patch, uint patchID : SV_PrimitiveID)
{
	PatchTess pt;

	pt.EdgeTess[0] = 0.5f * (patch[1].tessFactor + patch[2].tessFactor);
	pt.EdgeTess[1] = 0.5f * (patch[0].tessFactor + patch[2].tessFactor);
	pt.EdgeTess[2] = 0.5f * (patch[0].tessFactor + patch[1].tessFactor);

	pt.InsideTess = pt.EdgeTess[0];

	return pt;
}

///////////////////////
// Hull Shader
///////////////////////
[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("BasicTessellationConstHullShader")]
[maxtessfactor(64.0f)]
HullOut BasicTessellationHullShader(InputPatch<HullInputType, 3> patch,
 uint i : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
	HullOut output;

	output.position = patch[i].position;
	output.tex = patch[i].tex;
	output.normal = patch[i].normal;
	output.tangent = patch[i].tangent;
	output.binormal = patch[i].binormal;
	output.viewRay = patch[i].viewRay;
	output.worldPosition = patch[i].worldPosition;
	output.localPosition = patch[i].localPosition;
	output.RTlndex = patch[i].RTlndex;

	return output;
}