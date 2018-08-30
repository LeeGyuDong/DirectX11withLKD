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
    float middleGray; //�̰� ��� : HDR -> LDR�� ��ȯ������ ������ �� ������ ũ�Ⱑ Ŀ��
    float lumWhiteSqr;  //��� : ��ü���� ���, ������ ��ο�, ���� �����
    float deltaTime;
    float bloomScale;
    int hdrOn;
    int bloomOn;
    float2 postProcessPadding;
};

/////////////////////////��üũ�Ⱑ 1/16�� �ٿ����
[numthreads(8, 8, 1)] //�̰� ȭ���� ũ�⿡ ���� : 1920 / 4  -> (�Ѻ��� �ִ� 480 ���� �������ʿ�) < (������׷� �Ѻ��� 64�� * �׷쳻 �Ѻ� 8�� = 512 )
void DownScaleComputeMain(int3 dispatchThreadID : SV_DispatchThreadID) //0,0 ���ͽ���
{
    //g_Texture�� r32g32...��Ʈ��
    //RWTexture2D�� r8g8...
    //�̸鼭 ���� ���� �ؽ��� ũ�Ⱑ ���ٸ� 1:1 ������ : result = g_TextureMap[int2(dispatchThreadID.x * 4, dispatchThreadID.y * 2)];
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


    //1920 / 4 / 4 ��
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
    //��������ϸ� one = ��ü�� �ϳ����ļ� ������.
    g_Target[dispatchThreadID.xy] = result;


    if (dispatchThreadID.x == 0 && dispatchThreadID.y == 0)
    {
        //�ֵ��� ���̰� �ʹ� ũ�� �׳� ������ ��ȯ
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
        //�ƴϸ� õõ�� ��ȯ
        else
        {
            one = one * float4(0.299f, 0.587f, 0.114f, 0.0f);
            g_AverageLum[int2(0, 0)] = lerp(g_AverageLum[int2(0, 0)], one, deltaTime );
        }
    }


    //Bloom ���
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





