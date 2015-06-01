float digitBin(const int x)
{
    return x == 0 ? 480599.0 :
           x == 1 ? 139810.0 :
           x == 2 ? 476951.0 :
           x == 3 ? 476999.0 :
           x == 4 ? 350020.0 :
           x == 5 ? 464711.0 :
           x == 6 ? 464727.0 :
           x == 7 ? 476228.0 :
           x == 8 ? 481111.0 :
           x == 9 ? 481095.0 :
           0.0;
}

float printNumber(
    const vec2 fragCoord,
    const vec2 pixelCoords,
    const vec2 fontSize,
    const float number,
    const float maxDigits,
    const float decimalPlaces
)
{
    vec2 stringCharCoords = (fragCoord - pixelCoords) / fontSize;
    if((stringCharCoords.y < 0.0) || (stringCharCoords.y >= 1.0)) return 0.0;

	float log10Number = log2(abs(number)) / log2(10.0);
	float biggestIndex = max(floor(log10Number), 0.0);
	float digitIndex = maxDigits - floor(stringCharCoords.x);
	float charBin = 0.0;
	if(digitIndex > (-decimalPlaces - 1.01))
    {
		if(digitIndex > biggestIndex)
        {
			if((number < 0.0) && (digitIndex < (biggestIndex+1.5))) charBin = 1792.0;
		}
        else
        {
			if(digitIndex == -1.0)
            {
				if(decimalPlaces > 0.0) charBin = 2.0;
			}
            else
            {
				if(digitIndex < 0.0) digitIndex += 1.0;
				float digitValue = (abs(number / (pow(10.0, digitIndex))));
                const float fix = 0.0001;
                charBin = digitBin(int(floor(mod(fix+digitValue, 10.0))));
			}
		}
	}

    return floor(mod((charBin / pow(2.0, floor(fract(stringCharCoords.x) * 4.0) + (floor(stringCharCoords.y * 5.0) * 4.0))), 2.0));
}
