using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Planet : MonoBehaviour
{
    public Transform skySphere;

    public float planetRadius           = 500;
    public float astomsphereThickness   = 1.6f;
    public float radiusScale            = 1;

    public float NormalizeFactor
    {
        get
        {
            return 1 / astomsphereThickness;
        }
    }

    // Update is called once per frame
    void Update()
    {
        var scale = planetRadius * radiusScale;
        transform.localScale = new Vector3(scale, scale, scale);

        if(skySphere != null)
        {
            var skyScale = (planetRadius + astomsphereThickness) * radiusScale;
            skySphere.localScale = new Vector3(skyScale, skyScale, skyScale);
        }

        float normalizedPlanetRadius = planetRadius * NormalizeFactor;
        Shader.SetGlobalFloat("_PlanetRadius", normalizedPlanetRadius);
        Shader.SetGlobalFloat("_SkyRadius", normalizedPlanetRadius + 1);
    }
}