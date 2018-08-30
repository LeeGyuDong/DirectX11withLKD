////////////////////////////////////////////
// FileName : PixelShader.ps
////////////////////////////////////////////

Texture2D g_TextureMap : register(t0);
RWTexture2D<float4> g_Target : register(u0);
RWTexture2D<float4> g_AverageLum : register(u1);
RWTexture2D<float4> g_BloomLum : register(u2);

///////////////////////               
// Compute Shader
///////////////////////

static const float sampleWeights[13] =
{
    0.002216,
    0.008764,
    0.026995,
    0.064759,
    0.120985,
    0.176033,
    0.199471,
    0.176033,
    0.120985,
    0.064759,
    0.026995,
    0.008764,
    0.002216,
};

cbuffer PostProcessBuffer : register(b0)
{
    float middleGray; //이건 상수 : HDR -> LDR의 변환스케일 높으면 빛 번지는 크기가 커짐
    float lumWhiteSqr;  //상수 : 전체적인 밝기, 높으면 어두움, 위랑 비슷함
    float deltaTime;
    float bloomScale;
    int hdrOn;
    int bloomOn;
    float2 postProcessPadding;
};

/////////////////////////전체크기가 1/16로 다운스케일
[numthreads(8, 8, 1)] //이건 화면의 크기에 의존 : 1920 / 4  -> (한변에 최대 480 개의 스레드필요) < (스레드그룹 한변에 64개 * 그룹내 한변 8개 = 512 )
void DownScaleComputeMain(int3 dispatchThreadID : SV_DispatchThreadID) //0,0 부터시작
{
    //g_Texture는 r32g32...비트형
    //RWTexture2D는 r8g8...
    //이면서 만약 둘의 텍스쳐 크기가 같다면 1:1 대응은 : result = g_TextureMap[int2(dispatchThreadID.x * 4, dispatchThreadID.y * 2)];
    float4 one = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 result = float4(0.0f, 0.0f, 0.0f, 0.0f);

    int i, j;
    
    for(i = 0; i < 4; i++)
    {
        for (j = 0; j < 4; j++)
        {
            result += g_TextureMap[int2(dispatchThreadID.x * 4 * 4, dispatchThreadID.y * 2 * 4) + int2(i,j)];
        }
    }
    result /= 16;
    g_Target[dispatchThreadID.xy] = result;
    GroupMemoryBarrierWithGroupSync();


    //1920 / 4 / 4 함
    for (i = 0; i < 4; i++)
    {
        for (j = 0; j < 4; j++)
        {
            one += g_Target[int2(dispatchThreadID.x * 4, dispatchThreadID.y * 4) + int2(i, j)];
        }
    }
    one /= 16;
    GroupMemoryBarrierWithGroupSync();
    g_Target[dispatchThreadID.xy] = one;

    //1920 / 4 / 4 / 4 = 30
    one = float4(0.0f, 0.0f, 0.0f, 0.0f);
    for (i = 0; i < 4; i++)
    {
        for (j = 0; j < 4; j++)
        {
            one += g_Target[int2(dispatchThreadID.x * 4, dispatchThreadID.y * 4) + int2(i, j)];
        }
    }
    one /= 16;
    GroupMemoryBarrierWithGroupSync();
    g_Target[dispatchThreadID.xy] = one;

    //1920 / 4 / 4 / 4 = 30 / 4 = 7.5
    one = float4(0.0f, 0.0f, 0.0f, 0.0f);
    for (i = 0; i < 4; i++)
    {
        for (j = 0; j < 4; j++)
        {
            one += g_Target[int2(dispatchThreadID.x * 4, dispatchThreadID.y * 4) + int2(i, j)];
        }
    }
    one /= 16;
    GroupMemoryBarrierWithGroupSync();
    g_Target[dispatchThreadID.xy] = one;

    //1920 / 4 / 4 / 4 = 30 / 4 = 7.5 / 4 = 2
    one = float4(0.0f, 0.0f, 0.0f, 0.0f);
    for (i = 0; i < 4; i++)
    {
        for (j = 0; j < 4; j++)
        {
            one += g_Target[int2(dispatchThreadID.x * 4, dispatchThreadID.y * 4) + int2(i, j)];
        }
    }
    one /= 16;
    GroupMemoryBarrierWithGroupSync();
    g_Target[dispatchThreadID.xy] = one;

    //1920 / 4 / 4 / 4 = 30 / 4 = 7.5 / 4 /2 = 1
    one = float4(0.0f, 0.0f, 0.0f, 0.0f);
    for (i = 0; i < 2; i++)
    {
        for (j = 0; j < 2; j++)
        {
            one += g_Target[int2(dispatchThreadID.x * 2, dispatchThreadID.y * 2) + int2(i, j)];
        }
    }
    one /= 4;
    GroupMemoryBarrierWithGroupSync();
    //여기까지하면 one = 전체를 하나합쳐서 나눈것.
    g_Target[dispatchThreadID.xy] = result;


    if (dispatchThreadID.x == 0 && dispatchThreadID.y == 0)
    {
        //휘도의 차이가 너무 크면 그냥 빠르게 변환
        float lumDiff = abs(dot(one, float4(0.299f, 0.587f, 0.114f, 0.0f)) - dot(g_AverageLum[int2(0, 0)], float4(1.0f, 1.0f, 1.0f, 0.0f)));
        if (lumDiff > 3.0f)
        {
            one = one * float4(0.299f, 0.587f, 0.114f, 0.0f);
            g_AverageLum[int2(0, 0)] = lerp(g_AverageLum[int2(0, 0)], one, deltaTime * 8);
        }
        else  if (lumDiff > 2.0f)
        {
            one = one * float4(0.299f, 0.587f, 0.114f, 0.0f);
            g_AverageLum[int2(0, 0)] = lerp(g_AverageLum[int2(0, 0)], one, deltaTime * 4);
        }
        else if (lumDiff > 1.0f)
        {
            one = one * float4(0.299f, 0.587f, 0.114f, 0.0f);
            g_AverageLum[int2(0, 0)] = lerp(g_AverageLum[int2(0, 0)], one, deltaTime * 2);
        }
        //아니면 천천히 변환
        else
        {
            one = one * float4(0.299f, 0.587f, 0.114f, 0.0f);
            g_AverageLum[int2(0, 0)] = lerp(g_AverageLum[int2(0, 0)], one, deltaTime );
        }
    }


    //Bloom 계산
    //g_BloomLum[dispatchThreadID.xy] = g_Target[dispatchThreadID.xy] - g_AverageLum[int2(0, 0)];
    g_BloomLum[dispatchThreadID.xy] = g_Target[dispatchThreadID.xy];
    GroupMemoryBarrierWithGroupSync();

    //horizon
    result = float4(0.0f, 0.0f, 0.0f, 0.0f);
    for (i = -6; i <= 6; i++)
        result += g_BloomLum[dispatchThreadID.xy + int2(i,0)] * sampleWeights[i + 6] ;


   
    GroupMemoryBarrierWithGroupSync();
    g_BloomLum[dispatchThreadID.xy] = result;


    //vertical
    result = float4(0.0f, 0.0f, 0.0f, 0.0f);
    for (i = -6; i <= 6; i++)
         result += g_BloomLum[dispatchThreadID.xy + int2(0, i)] * sampleWeights[i + 6];


    GroupMemoryBarrierWithGroupSync();
    g_BloomLum[dispatchThreadID.xy] = result;



}





