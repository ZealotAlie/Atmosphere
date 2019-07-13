using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OrbitCameraController : MonoBehaviour
{
    public Planet planet;

    public float moveSpeed      = 1;
    public float rotateSpeed    = 60;
    public float orbitHeight    = 0;

    [Range(0, 89.5f)]
    public float pitchLimit     = 89;

    float mPitch;

    void LateUpdate()
    {
        //Handle move first
        Vector3 moveDir     = new Vector3();
        float leftRight     = Input.GetAxis("Horizontal");
        float forwardBack   = Input.GetAxis("Vertical");

        moveDir += transform.right * leftRight + transform.forward * forwardBack;

        Vector3 axis        = Vector3.Cross(transform.position, moveDir);
        float orbitRadius   = orbitHeight + planet.planetRadius;
        float theta         = Time.deltaTime * moveSpeed / orbitRadius;

        transform.RotateAround(Vector3.zero, axis, theta);

        Vector3 planetUp    = transform.position.normalized;
        transform.position  = planetUp * orbitRadius;

        //Handle rotate second
        float rotDt         = rotateSpeed * Time.deltaTime;
        float rotLeftRight  = Input.GetAxis("Mouse X");
        float rotUpDown     = Input.GetAxis("Mouse Y");

        mPitch = Mathf.Clamp(mPitch + rotUpDown * rotDt, -pitchLimit, pitchLimit);

        Vector3 baseForward = Vector3.Cross(transform.right, planetUp);
        transform.rotation  = Quaternion.LookRotation(baseForward, planetUp)//Build base rotation
            * Quaternion.AngleAxis(mPitch, Vector3.left) * Quaternion.AngleAxis(rotLeftRight * rotDt, Vector3.up);//Apply pitch and yaw

        UpdateShaderValues();
    }

    void UpdateShaderValues()
    {
        Vector3 cameraPos           = transform.position;
        float cameraDistanceToCore  = cameraPos.magnitude;
        float normalizedFactor      = planet.NormalizeFactor;

        Shader.SetGlobalFloat("_CameraHeight", (cameraDistanceToCore - planet.planetRadius) * normalizedFactor);
        Shader.SetGlobalVector("_CameraPosition", cameraPos * normalizedFactor);
        Shader.SetGlobalVector("_CoreToCameraDir", cameraPos / cameraDistanceToCore);
    }
}