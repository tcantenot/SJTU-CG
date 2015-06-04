#include "../material.glsl"

const Material MatRedAcrylic = Material(DIFFUSE,
    vec3(0.87, 0.15, 0.15), 1.491, vec3(1.0), 0.0, vec3(0.0), NO_AS
);

const Material MatGreenAcrylic = Material(DIFFUSE,
    vec3(0.15, 0.87, 0.15), 1.491, vec3(1.0), 0.0, vec3(0.0), NO_AS
);

const Material MatBlueAcrylic = Material(DIFFUSE,
    vec3(0.15, 0.15, 0.87), 1.491, vec3(1.0), 0.0, vec3(0.0), NO_AS
);

const Material MatOrangeAcrylic = Material(DIFFUSE,
    vec3(0.93, 0.33, 0.04), 1.491, vec3(1.0), 0.0, vec3(0.0), NO_AS
);

const Material MatPurpleAcrylic = Material(DIFFUSE,
    vec3(0.5, 0.1, 0.9), 1.491, vec3(1.0), 0.0, vec3(0.0), NO_AS
);

const Material MatGlass = Material(REFRACTIVE,
    vec3(0.0), 2.42, vec3(1.0), 0.0, vec3(0.0), NO_AS       // Flint
);

const Material MatGreenGlass = Material(REFRACTIVE,
    vec3(0.0), 1.62, vec3(1.0), 0.0, vec3(0.0),
    AbsorptionAndScattering(vec3(1.0, 0.01, 1.0), 0.0)
);

const Material MatMarble = Material(REFRACTIVE,
    vec3(0.0), 1.486, vec3(1.0), 0.0, vec3(0.0),
    AbsorptionAndScattering(vec3(0.6), 8.0)
);

const Material MatSomething = Material(REFRACTIVE,
    vec3(0.0), 1.333, vec3(1.0), 0.0, vec3(0.0),
    AbsorptionAndScattering(vec3(0.9, 0.3, 0.02), 2.0)
);

const Material MatKetchup = Material(REFRACTIVE,
    vec3(0.0), 1.350, vec3(1.0), 0.0, vec3(0.0),
    AbsorptionAndScattering(vec3(0.02, 5.1, 5.7), 9.0)
);

const Material MatWhite = Material(DIFFUSE,
    vec3(0.9), 0.0, vec3(0.0), 0.0, vec3(0.0), NO_AS
);

const Material MatYellow = Material(DIFFUSE,
    vec3(0.7, 0.7, 0.1), 2.0, vec3(0.0), 0.0, vec3(0.0), NO_AS
);

const Material MatLightBlue = Material(DIFFUSE,
    vec3(0.4, 0.6, 0.8), 1.2, vec3(0.0), 0.0, vec3(0.0), NO_AS
);

const Material MatGold = Material(METALLIC,
    vec3(0.0), 0.0, vec3(0.869, 0.621, 0.027), 0.0, vec3(0.0), NO_AS
);

const Material MatSteel = Material(METALLIC,
    vec3(0.0), 0.0, vec3(0.89), 0.0, vec3(0.0), NO_AS
);

const Material MatWhiteLight = Material(DIFFUSE, // FIXME
    vec3(0.0), 0.0, vec3(0.0), 0.0, vec3(13, 13, 11), NO_AS
);

const Material MatGround = Material(DIFFUSE,
    vec3(0.455, 0.43, 0.39),
    /*vec3(1.0),*/
    1.2, vec3(0.0), 0.02, vec3(0.0),
    AbsorptionAndScattering(vec3(0.0), 0.0)
);

