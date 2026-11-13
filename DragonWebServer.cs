using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;

class DragonWebServer
{
    private static int port = 8080;
    private static string rootDir = AppDomain.CurrentDomain.BaseDirectory;

    private static readonly Dictionary<string, string> mimeTypes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
    {
        { ".html", "text/html; charset=utf-8" },
        { ".htm",  "text/html; charset=utf-8" },
        { ".css",  "text/css" },
        { ".js",   "application/javascript" },
        { ".wasm", "application/wasm" },
        { ".data", "application/octet-stream" },
        { ".json", "application/json" },
        { ".png",  "image/png" },
        { ".jpg",  "image/jpeg" },
        { ".jpeg", "image/jpeg" },
        { ".ico",  "image/x-icon" },
        { ".txt",  "text/plain" }
    };

    static void Main(string[] args)
    {
        int p;
        if (args.Length > 0 && int.TryParse(args[0], out p))
        {
            port = p;
        }

        Console.Title = "DragonBoy Web Server (Port " + port + ")";
        Console.WriteLine("==========================================================");
        Console.WriteLine(" NRO WEB SERVER DANG CHAY TAI PORT " + port + " !");
        Console.WriteLine(" Truy cap tu may khac: http://47.129.2.246:" + port);
        Console.WriteLine(" Nhan Ctrl+C de dung server.");
        Console.WriteLine("==========================================================");

        HttpListener listener = null;
        string[] prefixes = new string[]
        {
            "http://*:" + port + "/",
            "http://+:" + port + "/",
            "http://0.0.0.0:" + port + "/",
            "http://localhost:" + port + "/",
            "http://127.0.0.1:" + port + "/"
        };

        foreach (string prefix in prefixes)
        {
            try
            {
                listener = new HttpListener();
                listener.Prefixes.Add(prefix);
                listener.Start();
                Console.WriteLine("[INFO] Successfully bound Web Server to " + prefix);
                break;
            }
            catch
            {
                listener = null;
            }
        }

        if (listener == null)
        {
            Console.WriteLine("[ERROR] Khong the khoi dong Web Server tren port " + port);
            return;
        }

        while (listener.IsListening)
        {
            try
            {
                HttpListenerContext ctx = listener.GetContext();
                ThreadPool.QueueUserWorkItem(state => ProcessRequest(ctx));
            }
            catch (Exception)
            {
                if (!listener.IsListening) break;
            }
        }
    }

    private static void ProcessRequest(HttpListenerContext ctx)
    {
        try
        {
            HttpListenerRequest req = ctx.Request;
            HttpListenerResponse res = ctx.Response;

            string rawPath = Uri.UnescapeDataString(req.Url.LocalPath);
            if (string.IsNullOrEmpty(rawPath) || rawPath == "/")
            {
                rawPath = "/index.html";
            }

            string relPath = rawPath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
            string fullPath = Path.Combine(rootDir, relPath);

            if (File.Exists(fullPath))
            {
                string ext = Path.GetExtension(fullPath);
                string mime = "application/octet-stream";
                if (!string.IsNullOrEmpty(ext) && mimeTypes.ContainsKey(ext))
                {
                    mime = mimeTypes[ext];
                }

                res.ContentType = mime;
                res.AddHeader("Access-Control-Allow-Origin", "*");
                res.AddHeader("Cache-Control", "no-cache");

                using (FileStream fs = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                {
                    res.ContentLength64 = fs.Length;
                    byte[] buffer = new byte[65536];
                    int read;
                    while ((read = fs.Read(buffer, 0, buffer.Length)) > 0)
                    {
                        res.OutputStream.Write(buffer, 0, read);
                    }
                }
                res.Close();
            }
            else
            {
                res.StatusCode = 404;
                res.Close();
            }
        }
        catch (Exception)
        {
            // Aborted or disconnected by client - abort safely without crashing
            try { ctx.Response.Abort(); } catch { }
        }
    }
}
