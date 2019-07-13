using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Atmosphere : MonoBehaviour
{
    public int WavelengthR = 680;
    public int WavelengthG = 550;
    public int WavelengthB = 440;

    public Color atmosphereTint = Color.white;

    public float betaFactory = 0.1f;
    public float mieFactor = 0.02f;

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("_SunAtmosphereTint", atmosphereTint);
        float lambdaR = WavelengthR * 0.001f;
        float lambdaG = WavelengthG * 0.001f;
        float lambdaB = WavelengthB * 0.001f;

        Vector3 beta = new Vector3()
        {
            x = 1 / Mathf.Pow(lambdaR, 4.0f),
            y = 1 / Mathf.Pow(lambdaG, 4.0f),
            z = 1 / Mathf.Pow(lambdaB, 4.0f)
        };

        Shader.SetGlobalVector("_Beta", beta * betaFactory);

        Shader.SetGlobalVector("_MieBeta", new Vector3(mieFactor, mieFactor, mieFactor));
    }
}
