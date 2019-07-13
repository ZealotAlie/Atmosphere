using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SunController : MonoBehaviour
{
    public Transform sun;

    [Range(-180,180)]
    public float theta;
    public float sunHeight;
    public float rotateSpeed    = 1;
    public float thetaLimit     = 120;

    // Update is called once per frame
    void Update()
    {
        if(sun == null)
        {
            return;
        }

        theta += Time.deltaTime * rotateSpeed;
        if(theta > thetaLimit)
        {
            theta -= thetaLimit * 2;
        }

        float thetaInRad = theta / 180 * Mathf.PI;

        Vector3 sunDir = new Vector3(Mathf.Sin(thetaInRad), Mathf.Cos(thetaInRad), 0);
        sun.transform.position = sunDir * sunHeight;
        Shader.SetGlobalVector("_SunDirection", sunDir);

        sun.transform.LookAt(transform);
    }
}
