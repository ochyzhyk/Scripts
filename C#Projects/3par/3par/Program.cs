using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using System.Diagnostics;
using System.Threading;
using System.IO;
using System.Web.Script.Serialization;
using Newtonsoft.Json.Linq;
using System.Net.Mail;



class Program
{
    static void Main()
    {
        Httprequest httprequest = new Httprequest();
        string key = httprequest.request();
        string cpguri = "https://10.10.10.10:8080/api/v1/capacity";
        httprequest.request(cpguri, key);
        Console.ReadLine();
    }
}

 

class Httprequest
{
    public string request()
    {
        string [] Key;
        string requestUri = "https://10.10.10.10:8080/api/v1/credentials";
        
        HttpWebRequest httpWebRequest = (HttpWebRequest)WebRequest.Create(requestUri);
        httpWebRequest.Method = WebRequestMethods.Http.Post;
        httpWebRequest.Accept = "application/json";
        httpWebRequest.ContentType = "application/json";
        httpWebRequest.ServerCertificateValidationCallback += (sender, certificate, chain, sslPolicyErrors) => true;
            
        using (var streamWriter = new StreamWriter(httpWebRequest.GetRequestStream()))
            {
                string json = "{ \"user\":\"admin\",\"password\":\"admin\" }";

                streamWriter.Write(json);
                streamWriter.Flush();
            }

        HttpWebResponse response = httpWebRequest.GetResponse() as HttpWebResponse;
        var httpResponse = (HttpWebResponse)httpWebRequest.GetResponse();

        using (var streamReader = new StreamReader(httpResponse.GetResponseStream()))
            {
                var responseText = streamReader.ReadToEnd();
                Console.WriteLine(responseText);
                Key = responseText.Split(new char[] {'\"'});
            }
        string key = Key[3].ToString(); 
        return key;

    }
    
    public void request(string requestUri, string key)
    {
        string FC, SSD;

        HttpWebRequest httpWebRequest = (HttpWebRequest)WebRequest.Create(requestUri);
        httpWebRequest.Method = WebRequestMethods.Http.Get;
        httpWebRequest.Headers.Add("X-HP3PAR-WSAPI-SessionKey", key);
        httpWebRequest.ServerCertificateValidationCallback += (sender, certificate, chain, sslPolicyErrors) => true;

        HttpWebResponse httpResponse = httpWebRequest.GetResponse() as HttpWebResponse;
        using (var streamReader = new StreamReader(httpResponse.GetResponseStream()))
        {
            string responseText = streamReader.ReadToEnd();
            Console.WriteLine(responseText);
            JObject o = JObject.Parse(responseText);
            FC = (string)o.SelectToken("FCCapacity.failedCapacityMiB");
            Console.WriteLine(FC);
            SSD = (string)o.SelectToken("SSDCapacity.failedCapacityMiB");
            Console.WriteLine(SSD);
        }

        return FC;

    }
}

//namespace _3par
//{
//    class Program
//    {
//        static void Main(string[] args)
//        {
//            string key;
//            string FC;
//            string SSD;
//            string requestUri = "https://10.10.10.10:8080/api/v1/credentials";
//            HttpWebRequest httpWebRequest = (HttpWebRequest)WebRequest.Create(requestUri);
//            httpWebRequest.Method = WebRequestMethods.Http.Post;
//            httpWebRequest.Accept = "application/json";
//            httpWebRequest.ContentType = "application/json";
//            httpWebRequest.Headers["Authorization"] = "Basic " + Convert.ToBase64String(Encoding.GetEncoding("ISO-8859-1").GetBytes("admin:admin"));

//            //httpWebRequest.Credentials = new NetworkCredential("admin","admin");
//            httpWebRequest.ServerCertificateValidationCallback += (sender, certificate, chain, sslPolicyErrors) => true;

//            using (var streamWriter = new StreamWriter(httpWebRequest.GetRequestStream()))
//            {
//                string json = "{ \"user\":\"admin\",\"password\":\"admin\" }";

//                streamWriter.Write(json);
//                streamWriter.Flush();
//            }

//            HttpWebResponse response = httpWebRequest.GetResponse() as HttpWebResponse;
//            var httpResponse = (HttpWebResponse)httpWebRequest.GetResponse();

//            using (var streamReader = new StreamReader(httpResponse.GetResponseStream()))
//            {
//                var responseText = streamReader.ReadToEnd();
//                Console.WriteLine(responseText);
//                int startID = 8;
//                int endID = responseText.LastIndexOf("\"");
//                key = responseText.Substring(startID, endID - startID);
//                Console.WriteLine(key);
//            }


//            string cpguri = "https://10.10.10.10:8080/api/v1/capacity";
//            httpWebRequest = (HttpWebRequest)WebRequest.Create(cpguri);
//            httpWebRequest.Method = WebRequestMethods.Http.Get;
//            httpWebRequest.Headers.Add("X-HP3PAR-WSAPI-SessionKey", key);
//            httpWebRequest.ServerCertificateValidationCallback += (sender, certificate, chain, sslPolicyErrors) => true;

//            httpResponse = httpWebRequest.GetResponse() as HttpWebResponse;
//            using (var streamReader = new StreamReader(httpResponse.GetResponseStream()))
//            {
//                string responseText = streamReader.ReadToEnd();
//                Console.WriteLine(responseText);
//                JObject o = JObject.Parse(responseText);
//                FC = (string)o.SelectToken("FCCapacity.failedCapacityMiB");
//                //foreach (JToken i in name)
//                Console.WriteLine(FC);
//                SSD = (string)o.SelectToken("SSDCapacity.failedCapacityMiB");
//                Console.WriteLine(SSD);
//            }


//            MailMessage mail = new MailMessage("3par@dc.local", "user@dc.local");
//            SmtpClient client = new SmtpClient();
//            client.Port = 25;
//            client.DeliveryMethod = SmtpDeliveryMethod.Network;
//            client.UseDefaultCredentials = false;
//            client.Host = "10.9.130.11";
//            mail.Subject = "Failed space.";
//            mail.IsBodyHtml = true;
//            mail.Body = "Failed disks on 3PAR" +
//                "\n<br>" +
//                "\n<table border='1'>" +
//                "\n<tr>" +
//                    "\n\t<th>Type of disks</th>" +
//                    "\n\t<th>Count</th>" +
//                "\n</tr>" +
//                "\n<tr>" +
//                    "\n\t<th>SSD</th>" +
//                    "\n\t<th>" + Math.Truncate(Convert.ToDouble(SSD) / 1024 / 1017) + "</th>" +
//                "\n</tr>" +
//                "\n<tr>" +
//                    "\n\t<th>FC</th>" +
//                    "\n\t<th>" + Math.Truncate(Convert.ToDouble(FC) / 1024 / 1017) + "</th>" +
//                "\n</tr>" +
//                "\n<table>";

//            if (Convert.ToInt32(SSD) != 0 | Convert.ToInt32(FC) != 0)
//                client.Send(mail);

//            //Console.ReadLine();
//        }
//    }
//}
