using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

class DragonProxy
{
    private static int listenPort = 8081;

    static void Main(string[] args)
    {
        int p;
        if (args.Length > 0 && int.TryParse(args[0], out p))
        {
            listenPort = p;
        }

        Console.Title = "DragonBoy WebSocket-to-TCP Proxy : Port " + listenPort;
        Console.WriteLine("=================================================");
        Console.WriteLine(" DragonBoy WebGL WebSocket <-> TCP Proxy Server  ");
        Console.WriteLine(" Listening on: ws://0.0.0.0:" + listenPort + "/");
        Console.WriteLine("=================================================");

        StartProxyAsync().GetAwaiter().GetResult();
    }

    private static HttpListener CreateAndStartListener(string prefix)
    {
        HttpListener l = new HttpListener();
        l.Prefixes.Add(prefix);
        l.Start();
        return l;
    }

    private static async Task StartProxyAsync()
    {
        HttpListener listener = null;
        string[] prefixes = new string[]
        {
            "http://*:" + listenPort + "/",
            "http://+:" + listenPort + "/",
            "http://0.0.0.0:" + listenPort + "/",
            "http://localhost:" + listenPort + "/",
            "http://127.0.0.1:" + listenPort + "/"
        };

        foreach (string prefix in prefixes)
        {
            try
            {
                listener = CreateAndStartListener(prefix);
                Console.WriteLine("[INFO] Successfully bound HttpListener to " + prefix);
                break;
            }
            catch (Exception ex)
            {
                Console.WriteLine("[WARN] Could not bind to " + prefix + " (" + ex.Message + ")");
            }
        }

        if (listener == null)
        {
            Console.WriteLine("[FATAL] Could not bind to any prefix on port " + listenPort);
            return;
        }

        Console.WriteLine("[INFO] Proxy listening and ready to accept connections.");

        while (true)
        {
            try
            {
                HttpListenerContext context = await listener.GetContextAsync();
                Task task = ProcessRequestAsync(context);
            }
            catch (Exception ex)
            {
                Console.WriteLine("[WARN] Accept error: " + ex.Message);
            }
        }
    }

    private static async Task ProcessRequestAsync(HttpListenerContext context)
    {
        if (!context.Request.IsWebSocketRequest)
        {
            try
            {
                string responseString = "<html><body style='font-family:sans-serif;text-align:center;padding:50px;'><h2>DragonBoy WebGL WebSocket-to-TCP Proxy is Running!</h2><p>Connect via WebSocket: ws://&lt;ip&gt;:" + listenPort + "/?targetHost=&lt;host&gt;&amp;targetPort=&lt;port&gt;</p></body></html>";
                byte[] buffer = Encoding.UTF8.GetBytes(responseString);
                context.Response.ContentType = "text/html; charset=utf-8";
                context.Response.ContentLength64 = buffer.Length;
                await context.Response.OutputStream.WriteAsync(buffer, 0, buffer.Length);
                context.Response.Close();
            }
            catch { }
            return;
        }

        string targetHost = context.Request.QueryString["targetHost"];
        string targetPortStr = context.Request.QueryString["targetPort"];
        int targetPort = 14445;

        if (string.IsNullOrEmpty(targetHost))
        {
            targetHost = "112.213.94.23";
        }
        int p;
        if (!string.IsNullOrEmpty(targetPortStr) && int.TryParse(targetPortStr, out p))
        {
            targetPort = p;
        }

        HttpListenerWebSocketContext wsContext;
        try
        {
            wsContext = await context.AcceptWebSocketAsync(null);
        }
        catch (Exception ex)
        {
            Console.WriteLine("[WARN] AcceptWebSocketAsync failed: " + ex.Message);
            context.Response.StatusCode = 500;
            context.Response.Close();
            return;
        }

        WebSocket ws = wsContext.WebSocket;
        string clientEndpoint = context.Request.RemoteEndPoint.ToString();
        Console.WriteLine(string.Format("[{0:HH:mm:ss}] [CONNECT] Client {1} -> Target TCP {2}:{3}", DateTime.Now, clientEndpoint, targetHost, targetPort));

        TcpClient tcp = new TcpClient();
        tcp.NoDelay = true;

        try
        {
            await tcp.ConnectAsync(targetHost, targetPort);
        }
        catch (Exception ex)
        {
            Console.WriteLine(string.Format("[{0:HH:mm:ss}] [ERROR] Cannot connect to TCP {1}:{2}: {3}", DateTime.Now, targetHost, targetPort, ex.Message));
            try { ws.Abort(); } catch { }
            tcp.Close();
            return;
        }

        NetworkStream tcpStream = tcp.GetStream();
        CancellationTokenSource cts = new CancellationTokenSource();

        Task t1 = PumpWsToTcpAsync(ws, tcpStream, cts.Token, clientEndpoint);
        Task t2 = PumpTcpToWsAsync(tcpStream, ws, cts.Token, clientEndpoint);

        await Task.WhenAny(t1, t2);
        cts.Cancel();

        try { tcp.Close(); } catch { }
        try { ws.Abort(); } catch { }
        Console.WriteLine(string.Format("[{0:HH:mm:ss}] [DISCONNECT] Session closed for {1}", DateTime.Now, clientEndpoint));
    }

    private static async Task PumpWsToTcpAsync(WebSocket ws, NetworkStream tcpStream, CancellationToken ct, string client)
    {
        byte[] buffer = new byte[8192];
        try
        {
            while (!ct.IsCancellationRequested && ws.State == WebSocketState.Open)
            {
                WebSocketReceiveResult result = await ws.ReceiveAsync(new ArraySegment<byte>(buffer), ct);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    break;
                }
                if (result.Count > 0)
                {
                    await tcpStream.WriteAsync(buffer, 0, result.Count, ct);
                    await tcpStream.FlushAsync(ct);
                }
            }
        }
        catch { }
    }

    private static async Task PumpTcpToWsAsync(NetworkStream tcpStream, WebSocket ws, CancellationToken ct, string client)
    {
        byte[] buffer = new byte[8192];
        try
        {
            while (!ct.IsCancellationRequested && ws.State == WebSocketState.Open)
            {
                int read = await tcpStream.ReadAsync(buffer, 0, buffer.Length, ct);
                if (read <= 0)
                {
                    break;
                }
                await ws.SendAsync(new ArraySegment<byte>(buffer, 0, read), WebSocketMessageType.Binary, true, ct);
            }
        }
        catch { }
    }
}
