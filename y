using System;
using System.IO;
using System.Net;
using System.Text;

namespace IndocEdgeIntegration
{
    class Program
    {
        static string sessionCookie = ""; // Will store "id=...; pid=..."

        static void Main()
        {
            try
            {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

                string baseUrl = "https://demo-integration/IndocEdge";
                string authUrl = baseUrl + "/AuthService/Login";
                string folderUrl = baseUrl + "/api/folder";
                string documentUrl = baseUrl + "/api/document";

                string username = "YOUR_USERNAME";
                string password = "YOUR_PASSWORD";

                Console.WriteLine("Authenticating...");
                if (!Authenticate(authUrl, username, password))
                {
                    Console.WriteLine("Authentication failed!");
                    return;
                }

                Console.WriteLine("Auth successful. Session cookie obtained: " + sessionCookie);

                // Example client info
                string clientId = "1234567";
                string clientName = "Filan";
                string clientSurname = "Fisteku";

                // Send Case Folder
                Console.WriteLine("Sending Case Folder...");
                string folderJson = BuildCaseFolder(clientId, clientName, clientSurname);
                string folderResp = PostJson(folderUrl, folderJson);
                Console.WriteLine("Folder Response: " + folderResp);

                // Send Document Metadata
                Console.WriteLine("Sending Document Metadata...");
                string docJson = BuildDocument(clientId, clientName, clientSurname);
                string docResp = PostJson(documentUrl, docJson);
                Console.WriteLine("Document Response: " + docResp);

                Console.WriteLine("Done.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Unhandled Exception: " + ex.Message);
            }

            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

        // Authenticate and store cookies manually
        static bool Authenticate(string url, string user, string pass)
        {
            try
            {
                var req = (HttpWebRequest)WebRequest.Create(url);
                req.Method = "POST";
                req.ContentType = "application/json";
                req.Accept = "application/json";
                req.AllowAutoRedirect = false;

                string body = "{ \"username\":\"" + user + "\", \"password\":\"" + pass + "\" }";
                byte[] data = Encoding.UTF8.GetBytes(body);

                using (var stream = req.GetRequestStream())
                    stream.Write(data, 0, data.Length);

                using (var resp = (HttpWebResponse)req.GetResponse())
                {
                    // Extract cookies manually
                    if (resp.Cookies.Count > 0)
                    {
                        sessionCookie = "";
                        foreach (Cookie c in resp.Cookies)
                        {
                            if (sessionCookie.Length > 0) sessionCookie += "; ";
                            sessionCookie += c.Name + "=" + c.Value;
                        }
                        return true;
                    }
                    else
                    {
                        Console.WriteLine("No cookies returned from auth.");
                        return false;
                    }
                }
            }
            catch (WebException ex)
            {
                if (ex.Response != null)
                {
                    using (var reader = new StreamReader(ex.Response.GetResponseStream()))
                        Console.WriteLine("Auth Error: " + reader.ReadToEnd());
                }
                else
                {
                    Console.WriteLine("Auth Exception: " + ex.Message);
                }
                return false;
            }
        }

        // Send JSON POST with manual cookie header
        static string PostJson(string url, string json)
        {
            try
            {
                var req = (HttpWebRequest)WebRequest.Create(url);
                req.Method = "POST";
                req.ContentType = "application/json";
                req.Accept = "application/json";
                req.Headers["Cookie"] = sessionCookie; // <-- manual cookie header

                byte[] data = Encoding.UTF8.GetBytes(json);
                using (var stream = req.GetRequestStream())
                    stream.Write(data, 0, data.Length);

                using (var resp = (HttpWebResponse)req.GetResponse())
                using (var reader = new StreamReader(resp.GetResponseStream()))
                {
                    return reader.ReadToEnd();
                }
            }
            catch (WebException ex)
            {
                if (ex.Response != null)
                {
                    using (var reader = new StreamReader(ex.Response.GetResponseStream()))
                        return "Error: " + reader.ReadToEnd();
                }
                return "Exception: " + ex.Message;
            }
        }

        // Build Case Folder JSON
        static string BuildCaseFolder(string id, string name, string surname)
        {
            return "{ " +
                "\"ParentId\":\"CLNT_PI\"," +
                "\"Key\":\"CLNT_PI_" + id + "\"," +
                "\"Name\":\"" + id + "\"," +
                "\"DocumentTypeId\":\"CLNT\"," +
                "\"Metadata\": { \"Items\": [" +
                    "{ \"DataType\":\"Text\",\"Key\":\"CLNTID\",\"Name\":\"Client ID\",\"Text\":\"" + id + "\" }," +
                    "{ \"DataType\":\"Text\",\"Key\":\"NAME\",\"Name\":\"Name\",\"Text\":\"" + name + "\" }," +
                    "{ \"DataType\":\"Text\",\"Key\":\"SRNM\",\"Name\":\"Surname\",\"Text\":\"" + surname + "\" }," +
                    "{ \"DataType\":\"Text\",\"Key\":\"CLNTTYP\",\"Name\":\"Client type\",\"Text\":\"PI\" }," +
                    "{ \"DataType\":\"Composite\",\"Key\":\"DCMTCDANDTTL\",\"Name\":\"Document code and title\",\"Composite\": {\"Items\": [" +
                        "{ \"DataType\":\"Text\",\"Key\":\"CODE\",\"Name\":\"Code\",\"Text\":\"3\" }," +
                        "{ \"DataType\":\"Text\",\"Key\":\"TTL\",\"Name\":\"Title\",\"Text\":\"Consent for access and processing of personal data\" }" +
                    "]}}" +
                "]}," +
                "\"IsCaseFolder\":\"true\"," +
                "\"AllowedDocumentTypes\":[\"CLNT\"]," +
                "\"RenameIfExists\":\"true\"," +
                "\"OnBehalfOf\":\"" + name + " " + surname + "\"," +
                "\"ReasonCode\":\"VPGL\"," +
                "\"ReasonBody\":\"Creating new case folder\"," +
                "\"ReasonType\":\"Administration\"" +
            "}";
        }

        // Build Document Metadata JSON
        static string BuildDocument(string id, string name, string surname)
        {
            return "{ " +
                "\"ParentId\":\"DIGPI\"," +
                "\"Key\":\"" + id + "-FORMULAR.pdf\"," +
                "\"Name\":\"Document\"," +
                "\"ClassificationClassId\":\"string\"," +
                "\"DocumentTypeId\":\"PRDCTRLT\"," +
                "\"Metadata\": { \"Items\": [" +
                    "{ \"DataType\":\"Text\",\"Key\":\"CLNTID\",\"Name\":\"Client ID\",\"Text\":\"" + id + "\" }," +
                    "{ \"DataType\":\"Text\",\"Key\":\"NAME\",\"Name\":\"Name\",\"Text\":\"" + name + "\" }," +
                    "{ \"DataType\":\"Text\",\"Key\":\"SRNM\",\"Name\":\"Surname\",\"Text\":\"" + surname + "\" }," +
                    "{ \"DataType\":\"Composite\",\"Key\":\"DCMTCDANDTTL\",\"Name\":\"Document code and title\",\"Composite\": {\"Items\": [" +
                        "{ \"DataType\":\"Text\",\"Key\":\"CODE\",\"Name\":\"Code\",\"Text\":\"82\" }," +
                        "{ \"DataType\":\"Text\",\"Key\":\"TTL\",\"Name\":\"Title\",\"Text\":\"Standard information form for consumer credit\" }" +
                    "]}}" +
                "]}," +
                "\"IsCaseFolder\":\"true\"," +
                "\"AllowedDocumentTypes\":[\"CLNT\"]," +
                "\"RenameIfExists\":\"true\"," +
                "\"OnBehalfOf\":\"" + name + " " + surname + "\"," +
                "\"ReasonCode\":\"VPGL\"," +
                "\"ReasonBody\":\"Creating new case folder\"," +
                "\"ReasonType\":\"Lookup\"" +
            "}";
        }
    }
}