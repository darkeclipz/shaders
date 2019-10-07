using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Explorer : MonoBehaviour
{
    public Material mat;
    public Vector2 pos;
    public float scale = 2.0f;
    public float angle = 0;
    public int maxIterations = 255;

    public float SmoothLerpSpeed = 0.075f;
    private Vector2 smoothPos;
    private float smoothScale = 2f;
    private float smoothAngle;
    private int smoothMaxIterations;

    void Start()
    {
        scale = 2f;
    }

    void UpdateShader()
    {
        smoothPos = Vector2.Lerp(smoothPos, pos, SmoothLerpSpeed);
        smoothScale = Mathf.Lerp(smoothScale, scale, SmoothLerpSpeed);
        smoothAngle = Mathf.Lerp(smoothAngle, angle, SmoothLerpSpeed);
        smoothMaxIterations = (int)Mathf.Lerp((float)smoothMaxIterations, (float)maxIterations, 0.03f);

        float aspect = (float)Screen.width / (float)Screen.height;

        float scaleX = smoothScale;
        float scaleY = smoothScale;

        if (aspect > 1f)
        {
            scaleY /= aspect;
        }
        else
        {
            scaleX *= aspect;
        }

        mat.SetVector("_Area", new Vector4(smoothPos.x, smoothPos.y, scaleX, scaleY));
        mat.SetFloat("_Angle", smoothAngle);
        mat.SetFloat("_MaxIterations", smoothMaxIterations);
    }

    void HandleInputs()
    {
        if(Input.GetKey(KeyCode.KeypadPlus))
        {
            scale *= 0.99f;
        }

        if(Input.GetAxis("Mouse ScrollWheel") > 0f)
        {
            scale *= 0.9f;
        }

        if(Input.GetKey(KeyCode.KeypadMinus))
        {
            scale *= 1.01f;
        }

        if(Input.GetAxis("Mouse ScrollWheel") < 0f)
        {
            scale *= 1.25f;
        }

        Vector2 dir = new Vector2(0.01f * scale, 0);
        float s = Mathf.Sin(angle);
        float c = Mathf.Cos(angle);
        dir = new Vector2(dir.x * c - dir.y * s, dir.x * s + dir.y * c);

        if(Input.GetKey(KeyCode.A))
        {
            pos -= dir;
        }

        if (Input.GetKey(KeyCode.D))
        {
            pos += dir;
        }

        dir = new Vector2(-dir.y, dir.x);
        if (Input.GetKey(KeyCode.S))
        {
            pos -= dir;
        }

        if (Input.GetKey(KeyCode.W))
        {
            pos += dir;
        }

        if (Input.GetKey(KeyCode.E))
        {
            angle -= 0.025f;
        }

        if (Input.GetKey(KeyCode.Q))
        {
            angle += 0.025f;
        }
    }
    
    void FixedUpdate()
    {
        UpdateShader();
        HandleInputs();
    }
}
