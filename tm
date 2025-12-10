using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;

namespace DmsTest
{
    class Program
    {
        static readonly string BASE_URL = "https://demo-integration.yourdomain.com/";
        static readonly string AUTH_URL = "https://demo-integration.yourdomain.com/security/loginprovideraddress";
        static readonly string CASE_FOLDER_URL = "https://demo-integration.yourdomain.com/api/casefolder";
        static readonly string DOCUMENT_URL = "https://demo-integration.yourdomain.com/api/document";

        // Hard-coded cookie values for testing
        private static readonly string HARD_CODED_SSID = "PASTE-SS-ID-HERE";
        private static readonly string HARD_CODED_SPID = "PASTE-SS-PID-HERE";

        static async Task Main(string[] args)
        {
            // Force IPv4 globally
            AppContext.SetSwitch("System.Net.DisableIPv6", true);

            Console.WriteLine("IPv4 forced ON.");

            var handler = new HttpClientHandler
            {
                UseCookies = true,
                CookieContainer = new CookieContainer(),
                AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate,
                ServerCertificateCustomValidationCallback =
                    (msg, cert, chain, errors) => true // ignore SSL for testing
            };

            using var client = new HttpClient(handler)
            {
                BaseAddress = new Uri(BASE_URL),
                Timeout = TimeSpan.FromSeconds(40)
            };

            //Attach the hard-coded cookies
            Console.WriteLine("Injecting test cookies...");
            handler.CookieContainer.Add(new Uri(BASE_URL), new Cookie("SS-ID", HARD_CODED_SSID));
            handler.CookieContainer.Add(new Uri(BASE_URL), new Cookie("SS-PID", HARD_CODED_SPID));

            Console.WriteLine("Cookies injected:");
            Console.WriteLine("SS-ID:  " + HARD_CODED_SSID);
            Console.WriteLine("SS-PID: " + HARD_CODED_SPID);

            // ----------------------------------------------
            // CREATE CASE FOLDER
            // ----------------------------------------------
            string caseFolderJson = @"{
              ""ParentId"": ""CLNT_PI"",
              ""Key"": ""CLNT_PI_1234567"",
              ""Name"": ""1234567"",
              ""DocumentTypeId"": ""CLNT"",
              ""Metadata"": {
                ""Items"": [
                  { ""DataType"": ""Text"", ""Key"": ""CLNTID"", ""Name"": ""Client ID"", ""Text"": ""1234567"" },
                  { ""DataType"": ""Text"", ""Key"": ""NAME"", ""Name"": ""Name"", ""Text"": ""Filan"" },
                  { ""DataType"": ""Text"", ""Key"": ""SRNM"", ""Name"": ""Surname"", ""Text"": ""Fisteku"" },
                  { ""DataType"": ""Text"", ""Key"": ""CLNTTYP"", ""Name"": ""Client type"", ""Text"": ""PI"" }
                ]
              },
              ""IsCaseFolder"": ""true"",
              ""AllowedDocumentTypes"": [ ""CLNT"" ],
              ""RenameIfExists"": ""true"",
              ""OnBehalfOf"": ""Filan Fisteku"",
              ""ReasonCode"": ""VPGL"",
              ""ReasonBody"": ""Creating new case folder"",
              ""ReasonType"": ""Administration""
            }";

            Console.WriteLine("\nSending CASE FOLDER...");
            var caseFolderContent = new StringContent(caseFolderJson, Encoding.UTF8, "application/json");

            HttpResponseMessage caseFolderResponse = null;

            try
            {
                caseFolderResponse = await client.PostAsync(CASE_FOLDER_URL, caseFolderContent);

                Console.WriteLine("Case folder status: " + caseFolderResponse.StatusCode);
                string body = await caseFolderResponse.Content.ReadAsStringAsync();
                Console.WriteLine("Response body:\n" + body);
            }
            catch (Exception ex)
            {
                Console.WriteLine("\nCase Folder ERROR:");
                Console.WriteLine(ex.Message);
                if (ex.InnerException != null) Console.WriteLine(ex.InnerException.Message);
            }

            // ----------------------------------------------
            // DOCUMENT (metadata only)
            // ----------------------------------------------

            string documentJson = @"{
                ""ParentId"": ""DIGPI"",
                ""Key"": ""12345678-FORMULAR.pdf"",
                ""Name"": ""FORMULAR"",
                ""DocumentTypeId"": ""PRDCTRLT"",
                ""Metadata"": {
                  ""Items"": [
                    { ""DataType"": ""Text"", ""Key"": ""CLNTID"", ""Name"": ""Client ID"", ""Text"": ""12345678"" },
                    { ""DataType"": ""Text"", ""Key"": ""NAME"", ""Name"": ""Name"", ""Text"": ""Arton"" },
                    { ""DataType"": ""Text"", ""Key"": ""SRNM"", ""Name"": ""Surname"", ""Text"": ""Muja"" },
                    { ""DataType"": ""Text"", ""Key"": ""CLNTTYP"", ""Name"": ""Client type"", ""Text"": ""PI"" }
                  ]
                },
                ""IsCaseFolder"": ""false"",
                ""RenameIfExists"": ""true"",
                ""OnBehalfOf"": ""Arton Muja"",
                ""ReasonCode"": ""VPGL"",
                ""ReasonBody"": ""Creating document"",
                ""ReasonType"": ""Lookup""
            }";

            Console.WriteLine("\nSending DOCUMENT metadata...");
            var docContent = new StringContent(documentJson, Encoding.UTF8, "application/json");

            HttpResponseMessage docResponse = null;

            try
            {
                docResponse = await client.PostAsync(DOCUMENT_URL, docContent);

                Console.WriteLine("Document status: " + docResponse.StatusCode);
                string body = await docResponse.Content.ReadAsStringAsync();
                Console.WriteLine("Response body:\n" + body);
            }
            catch (Exception ex)
            {
                Console.WriteLine("\nDocument ERROR:");
                Console.WriteLine(ex.Message);
                if (ex.InnerException != null) Console.WriteLine(ex.InnerException.Message);
            }

            Console.WriteLine("\nDONE.");
            Console.ReadLine();
        }
    }
}