#define GLITCH_PERIOD_LENGTH 0.1
#define GLITCH_PERIOD_MULTIPLIER (1 / GLITCH_PERIOD_LENGTH)
#define GLITCH_Y_LOW  10
#define GLITCH_Y_HIGH 5
#define GLITCH_X_LOW  -100
#define GLITCH_X_HIGH 100
#define GLITCH_FREQUENCY 50.0
#define SAMPLE_COUNT 13 // Lower this number to increase performance

#define SCALED_GAUSSIAN_SIGMA (1.25*Scale)

static const float M_PI = 3.14159265f;

// Source
// http://www.gamedev.net/topic/592001-random-number-generation-based-on-time-in-hlsl/
// Supposedly from the NVidia Direct3D10 SDK
// Slightly modified for my purposes
#define RANDOM_IA 16807
#define RANDOM_IM 2147483647
#define RANDOM_AM (1.0f/float(RANDOM_IM))
#define RANDOM_IQ 127773u
#define RANDOM_IR 2836
#define RANDOM_MASK 123459876

struct NumberGenerator {
    int seed; // Used to generate values.

    // Generates the next number in the sequence.
    void Cycle() {  
        seed ^= RANDOM_MASK;
        int k = seed / RANDOM_IQ;
        seed = RANDOM_IA * (seed - k * RANDOM_IQ ) - RANDOM_IR * k;

        if (seed < 0 ) 
            seed += RANDOM_IM;

        seed ^= RANDOM_MASK;
    }

    float GetRandomFloat(const float low, const float high)
    {
        Cycle();
        float v = RANDOM_AM * seed;
        return low * ( 1.0f - v ) + high * v;
    }

    float GetSeededFloat(const uint seedVal, const float low, const float high)
    {
        seed = int(seedVal * 123456789);
        return GetRandomFloat(low, high);
    }
};


Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings {
  float  Time;
  float  Scale;
  float2 Resolution;
  float4 Background;
};

float Gaussian2D(float x, float y, float sigma)
{
    return 1/(sigma*sqrt(2*M_PI)) * exp(-0.5*(x*x + y*y)/sigma/sigma);
}

float4 Blur(Texture2D input, float2 tex_coord, float2 glitch, float sigma)
{
    uint width, height;
    shaderTexture.GetDimensions(width, height);

    float texelWidth = 1.0f/width;
    float texelHeight = 1.0f/height;

    float4 color = { 0, 0, 0, 0 };

    for (int x = 0; x < SAMPLE_COUNT; x++)
    {
        float2 samplePos = { 0, 0 };
        float2 sampleGlitch;

        samplePos.x = tex_coord.x + (x - SAMPLE_COUNT/2) * texelWidth;
        for (int y = 0; y < SAMPLE_COUNT; y++)
        {
            samplePos.y = tex_coord.y + (y - SAMPLE_COUNT/2) * texelHeight;
            sampleGlitch = samplePos - glitch;

            if (sampleGlitch.x <= 0 ||
                sampleGlitch.y <= 0 || 
                sampleGlitch.x >= width || 
                sampleGlitch.y >= height) 
                    continue;

            color += input.Sample(samplerState, samplePos - glitch) * Gaussian2D((x - SAMPLE_COUNT/2), (y - SAMPLE_COUNT/2), sigma);
        }
    }

    return color;
}

float4 Glitch(Texture2D input, float2 tex, float2 glitch)
{
    float4 color;
    uint width, height;
    shaderTexture.GetDimensions(width, height);

    float2 pos = tex - glitch;
    if (pos.x <= 0 || pos.y <= 0 || pos.x >= width || pos.y >= height)
    {
        color = 0;
    }
    else
    {
        color = input.Sample(samplerState, pos);
    }

    return color;
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    Texture2D input = shaderTexture;
    float linePos;
    uint currentPeriod;
    float2 numPix;
    float2 pixSize;
    float2 glitch = { 0, 0 };
    float4 color;
    NumberGenerator rand;

    pixSize = 1.0 / Resolution;
    currentPeriod = Time * GLITCH_PERIOD_MULTIPLIER; 

    linePos = rand.GetSeededFloat(currentPeriod, 0.0, GLITCH_FREQUENCY);

    if (linePos < tex.y && tex.y < linePos + (rand.GetRandomFloat(GLITCH_Y_LOW, GLITCH_Y_HIGH) * pixSize.y))
    {
        glitch.x = rand.GetRandomFloat(GLITCH_X_LOW, GLITCH_X_HIGH) * pixSize.x;
    }

    // TODO Split these functions into two passes.
    color = Glitch(input, tex, glitch);
    color += Blur(input, tex, glitch, SCALED_GAUSSIAN_SIGMA)*0.3;

    return color;
}