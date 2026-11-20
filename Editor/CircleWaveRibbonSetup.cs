// Demo setup for the Circle Wave Ribbon: materials, the demo scene, and a few test renders.
// GameDevBox > Circle Wave Ribbon in the menu, or headless:
//   Unity.exe -batchmode -projectPath <project> -executeMethod GameDevBox.CircleWaveRibbonSetup.BatchBuildAndCapture -logFile <log>
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace GameDevBox
{
    public static class CircleWaveRibbonSetup
    {
        const string Root = "Assets/GameDevBox/Tutorials/Circle Wave Ribbon";
        const string ShaderPath = Root + "/Shaders/CircleWaveRibbon.shader";
        const string BackdropPath = Root + "/Shaders/RadialBackdrop.shader";
        const string GraphPath = Root + "/Shader Graph/Circle Wave Ribbon.shadergraph";
        const string ScenePath = Root + "/Scenes/Circle Wave Ribbon Demo.unity";

        // ------------------------------------------------------------ materials
        static Material MakeMaterial(Shader shader, string name, System.Action<Material> setup)
        {
            string path = $"{Root}/Materials/{name}.mat";
            var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat == null)
            {
                mat = new Material(shader) { name = name };
                AssetDatabase.CreateAsset(mat, path);
                setup?.Invoke(mat); // only on first creation so your own tweaks aren't overwritten
            }
            mat.shader = shader;
            EditorUtility.SetDirty(mat);
            return mat;
        }

        public static Dictionary<string, Material> BuildMaterials()
        {
            var shader = AssetDatabase.LoadAssetAtPath<Shader>(ShaderPath);
            var graph = AssetDatabase.LoadAssetAtPath<Shader>(GraphPath);
            var backdrop = AssetDatabase.LoadAssetAtPath<Shader>(BackdropPath);
            var mats = new Dictionary<string, Material>();
            mats["Spirit"] = MakeMaterial(shader, "Spirit Ribbon", m => { });
            mats["Ember"] = MakeMaterial(shader, "Ember Ribbon", m =>
            {
                m.SetColor("_FillColor", new Color(1f, 0.93f, 0.8f));
                m.SetColor("_EdgeColor", new Color(1f, 0.6f, 0.3f));
                m.SetColor("_GlowColor", new Color(1.3f, 0.45f, 0.1f));
                m.SetFloat("_Frequency", 5.6f);
                m.SetFloat("_Speed", 0.7f);
                m.SetFloat("_TimeOffset", 3.7f);
            });
            mats["Toxic"] = MakeMaterial(shader, "Toxic Ribbon", m =>
            {
                m.SetColor("_FillColor", new Color(0.88f, 1f, 0.92f));
                m.SetColor("_EdgeColor", new Color(0.45f, 0.95f, 0.7f));
                m.SetColor("_GlowColor", new Color(0.15f, 1.0f, 0.55f));
                m.SetFloat("_Roundness", 0.8f);
                m.SetFloat("_SineBlend", 0.35f);
                m.SetFloat("_Frequency", 4.2f);
                m.SetFloat("_TimeOffset", 8.1f);
            });
            if (graph != null) mats["Graph"] = MakeMaterial(graph, "Shader Graph Ribbon", m => { });
            if (backdrop != null) mats["Backdrop"] = MakeMaterial(backdrop, "Backdrop", m => { });
            AssetDatabase.SaveAssets();
            return mats;
        }

        // ------------------------------------------------------------ scene
        static GameObject Quad(string name, Material mat, Vector3 pos, Vector2 size)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Quad);
            go.name = name;
            Object.DestroyImmediate(go.GetComponent<Collider>());
            go.transform.position = pos;
            go.transform.localScale = new Vector3(size.x, size.y, 1);
            var r = go.GetComponent<MeshRenderer>();
            r.sharedMaterial = mat;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
            return go;
        }

        static GameObject Ribbon(string name, Material mat, Vector3 pos, float height, float aspect) =>
            Quad(name, mat, pos, new Vector2(height / aspect, height));

        [MenuItem("GameDevBox/Circle Wave Ribbon/Build Demo Scene")]
        public static void BuildDemoScene()
        {
            var mats = BuildMaterials();
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            var camGo = new GameObject("Main Camera") { tag = "MainCamera" };
            var cam = camGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.02f, 0.02f, 0.06f);
            cam.allowHDR = true;
            cam.transform.position = new Vector3(0, 2.0f, -7f);
            cam.fieldOfView = 40;
            var data = camGo.AddComponent<UniversalAdditionalCameraData>();
            data.renderPostProcessing = true;
            data.antialiasing = AntialiasingMode.SubpixelMorphologicalAntiAliasing;

            var volGo = new GameObject("Post Processing");
            var vol = volGo.AddComponent<Volume>();
            vol.isGlobal = true;
            string profilePath = $"{Root}/Scenes/Circle Wave Ribbon Volume.asset";
            var profile = AssetDatabase.LoadAssetAtPath<VolumeProfile>(profilePath);
            if (profile == null)
            {
                profile = ScriptableObject.CreateInstance<VolumeProfile>();
                AssetDatabase.CreateAsset(profile, profilePath);
            }
            if (!profile.TryGet(out Bloom bloom)) bloom = profile.Add<Bloom>(true);
            bloom.active = true;
            bloom.intensity.Override(0.3f);
            bloom.threshold.Override(1.2f);
            bloom.scatter.Override(0.65f);
            if (!profile.TryGet(out Tonemapping tone)) tone = profile.Add<Tonemapping>(true);
            tone.mode.Override(TonemappingMode.None); // otherwise the white fill turns grey
            if (!profile.TryGet(out Vignette vig)) vig = profile.Add<Vignette>(true);
            vig.intensity.Override(0.3f);
            vig.color.Override(new Color(0.02f, 0.0f, 0.05f));
            EditorUtility.SetDirty(profile);
            vol.sharedProfile = profile;

            if (mats.TryGetValue("Backdrop", out var bd))
                Quad("Backdrop", bd, new Vector3(0, 2.0f, 6f), new Vector2(17.8f, 10f));

            Ribbon("Spirit Ribbon (HLSL)", mats["Spirit"], new Vector3(0, 2.0f, 0), 4.4f, 2f);
            Ribbon("Ember Ribbon (HLSL)", mats["Ember"], new Vector3(-2.9f, 1.6f, 1f), 3.4f, 2f);
            Ribbon("Toxic Ribbon (HLSL)", mats["Toxic"], new Vector3(2.9f, 1.6f, 1f), 3.4f, 2f);
            if (mats.TryGetValue("Graph", out var g))
            {
                var go = Ribbon("Shader Graph Ribbon", g, new Vector3(5.2f, 2.0f, 1.5f), 4.4f, 2f);
                go.SetActive(false); // turn on to compare with the HLSL version
            }

            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();
            Debug.Log("[CircleWaveRibbon] demo scene saved: " + ScenePath);
        }

        // ------------------------------------------------------------ checks and captures
        static bool CheckShader(string path)
        {
            var shader = AssetDatabase.LoadAssetAtPath<Shader>(path);
            if (shader == null) { Debug.LogError($"[CircleWaveRibbon] missing shader at {path}"); return false; }
            var msgs = ShaderUtil.GetShaderMessages(shader);
            foreach (var m in msgs)
                Debug.Log($"[CircleWaveRibbon] {path}: {m.severity} {m.message} (line {m.line}) {m.file}");
            bool ok = !ShaderUtil.ShaderHasError(shader) && !msgs.Any(m => m.severity == UnityEditor.Rendering.ShaderCompilerMessageSeverity.Error);
            Debug.Log($"[CircleWaveRibbon] {path}: {(ok ? "OK" : "HAS ERRORS")} ({shader.name}, {msgs.Length} messages)");
            return ok;
        }

        static void Capture(Camera cam, string file, int w = 1920, int h = 1080)
        {
            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.DefaultHDR);
            rt.Create();
            cam.targetTexture = rt;
            cam.Render();
            var ldr = new RenderTexture(w, h, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
            Graphics.Blit(rt, ldr);
            RenderTexture.active = ldr;
            var tex = new Texture2D(w, h, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
            tex.Apply();
            RenderTexture.active = null;
            cam.targetTexture = null;
            Directory.CreateDirectory(Path.GetDirectoryName(file));
            File.WriteAllBytes(file, tex.EncodeToPNG());
            Object.DestroyImmediate(tex);
            rt.Release();
            ldr.Release();
            Debug.Log("[CircleWaveRibbon] captured " + file);
        }

        [MenuItem("GameDevBox/Circle Wave Ribbon/Capture Test Frames")]
        public static void CaptureFrames()
        {
            var mats = BuildMaterials();
            if (!EditorSceneManager.GetActiveScene().path.EndsWith("Circle Wave Ribbon Demo.unity"))
                EditorSceneManager.OpenScene(ScenePath);
            var cam = Camera.main;
            string dir = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "Recordings", "Circle Wave Ribbon"));
            var ribbons = new[] { "Spirit", "Ember", "Toxic" };
            var baseOffsets = ribbons.ToDictionary(k => k, k => mats[k].GetFloat("_TimeOffset"));
            float[] times = { 0f, 0.7f, 1.5f, 2.4f };
            for (int i = 0; i < times.Length; i++)
            {
                foreach (var k in ribbons) mats[k].SetFloat("_TimeOffset", baseOffsets[k] + times[i]);
                Capture(cam, Path.Combine(dir, $"demo_{i}.png"));
            }

            // square close-up of the main ribbon
            var others = Object.FindObjectsByType<MeshRenderer>()
                .Where(r => r.gameObject.name != "Spirit Ribbon (HLSL)" && r.gameObject.name != "Backdrop")
                .Select(r => r.gameObject).ToList();
            foreach (var go in others) go.SetActive(false);
            var camPos = cam.transform.position;
            cam.transform.position = new Vector3(0, 2.1f, -6.9f);
            for (int i = 0; i < times.Length; i++)
            {
                mats["Spirit"].SetFloat("_TimeOffset", baseOffsets["Spirit"] + times[i] * 1.3f);
                Capture(cam, Path.Combine(dir, $"closeup_{i}.png"), 1080, 1080);
            }
            mats["Spirit"].SetFloat("_TimeOffset", baseOffsets["Spirit"]);

            // HLSL on the left, Shader Graph on the right
            if (mats.ContainsKey("Graph"))
            {
                cam.transform.position = new Vector3(0, 2.0f, -7f);
                var spirit = GameObject.Find("Spirit Ribbon (HLSL)");
                var graphRibbon = Ribbon("Graph Compare", mats["Graph"], new Vector3(1.6f, 2.0f, 0), 4.4f, 2f);
                spirit.transform.position = new Vector3(-1.6f, 2.0f, 0);
                Capture(cam, Path.Combine(dir, "hlsl_vs_graph.png"));
                Object.DestroyImmediate(graphRibbon);
                spirit.transform.position = new Vector3(0, 2.0f, 0);
            }
            cam.transform.position = camPos;
            foreach (var go in others) if (go.name != "Shader Graph Ribbon") go.SetActive(true);
            foreach (var k in ribbons) mats[k].SetFloat("_TimeOffset", baseOffsets[k]);
            AssetDatabase.SaveAssets();
        }

        // 4 seconds of the close-up as numbered frames (turn them into a video with ffmpeg)
        [MenuItem("GameDevBox/Circle Wave Ribbon/Capture Motion Frames")]
        public static void CaptureMotion()
        {
            var mats = BuildMaterials();
            if (!EditorSceneManager.GetActiveScene().path.EndsWith("Circle Wave Ribbon Demo.unity"))
                EditorSceneManager.OpenScene(ScenePath);
            var cam = Camera.main;
            string dir = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "Recordings", "Circle Wave Ribbon", "motion"));
            var hide = Object.FindObjectsByType<MeshRenderer>()
                .Where(r => r.gameObject.name != "Spirit Ribbon (HLSL)" && r.gameObject.name != "Backdrop")
                .Select(r => r.gameObject).Where(g => g.activeSelf).ToList();
            foreach (var go in hide) go.SetActive(false);
            var camPos = cam.transform.position;
            cam.transform.position = new Vector3(0, 2.1f, -6.9f);
            float start = mats["Spirit"].GetFloat("_TimeOffset");
            for (int f = 0; f < 120; f++)
            {
                mats["Spirit"].SetFloat("_TimeOffset", start + f / 30f);
                Capture(cam, Path.Combine(dir, $"f_{f:000}.png"), 720, 720);
            }
            mats["Spirit"].SetFloat("_TimeOffset", start);
            cam.transform.position = camPos;
            foreach (var go in hide) go.SetActive(true);
        }

        // for -executeMethod
        public static void BatchBuildAndCapture()
        {
            int code = 0;
            try
            {
                AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
                bool a = CheckShader(ShaderPath);
                bool b = CheckShader(GraphPath);
                bool c = CheckShader(BackdropPath);
                BuildDemoScene();
                CaptureFrames();
                code = a && b && c ? 0 : 2;
            }
            catch (System.Exception e)
            {
                Debug.LogException(e);
                code = 1;
            }
            EditorApplication.Exit(code);
        }
    }
}
