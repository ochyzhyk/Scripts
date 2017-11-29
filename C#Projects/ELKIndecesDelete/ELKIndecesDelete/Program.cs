using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using System.Diagnostics;
using System.Threading;
using System.IO;

namespace ELKIndecesDelete

{
    class Program
    {
        static void Main(string[] args)
        {
            string IndecesUri = "http://10.9.130.149:9201/_cat/indices/win*?v&h=index";
            WebClient webclient = new WebClient();
            string [] Indeces = (webclient.GetIndeces(IndecesUri)).Split('\n');
            
            foreach (string Index in Indeces)
                if (Index.Contains("win"))
                    webclient.DeleteIndeces(Index);
            //string[] Index = Indeces.Split(',') ;
            //Console.WriteLine(Indeces[1]);
            //Console.ReadLine();
        }
    }

    class WebClient
    {
        public string GetIndeces (string IndecesUri)
        {
            string Indeces;
            HttpWebRequest httpWebRequest = (HttpWebRequest)WebRequest.Create(IndecesUri);
            httpWebRequest.Method = WebRequestMethods.Http.Get;
            httpWebRequest.Headers["Authorization"] = "Basic " + Convert.ToBase64String(Encoding.GetEncoding("ISO-8859-1").GetBytes("user:pass"));
            httpWebRequest.ServerCertificateValidationCallback += (sender, certificate, chain, sslPolicyErrors) => true;
            
            HttpWebResponse response = httpWebRequest.GetResponse() as HttpWebResponse;
            var httpResponse = (HttpWebResponse)httpWebRequest.GetResponse();
            using (var streamReader = new StreamReader(httpResponse.GetResponseStream()))
            {
                Indeces = streamReader.ReadToEnd();
            }
            
            return Indeces;
        }

        public void DeleteIndeces (string Index)
        {
            string Result;
            string [] Id = Index.Split('-');
            DateTime indexDate = Convert.ToDateTime(Id[1]);
            Console.WriteLine("Найден индекс за дату {0} \nНажмите Enter", indexDate.ToString("dd/MM/yyyy"));
            if (indexDate < DateTime.Today.AddDays(-3))
            {
                string deleteUri = "http://10.9.130.149:9201/" + Index + "?pretty";
                HttpWebRequest httpWebRequest = (HttpWebRequest)WebRequest.Create(deleteUri);
                httpWebRequest.Method = "DELETE";
                httpWebRequest.Headers["Authorization"] = "Basic " + Convert.ToBase64String(Encoding.GetEncoding("ISO-8859-1").GetBytes("user:pass"));
                httpWebRequest.ServerCertificateValidationCallback += (sender, certificate, chain, sslPolicyErrors) => true;

                HttpWebResponse response = httpWebRequest.GetResponse() as HttpWebResponse;
                var httpResponse = (HttpWebResponse)httpWebRequest.GetResponse();
                using (var streamReader = new StreamReader(httpResponse.GetResponseStream()))
                {
                    Result = streamReader.ReadToEnd();
                }
                Console.WriteLine("Удален индекс {0} \nНажмите Enter", (deleteUri + Result));
            }
            
            Console.ReadLine();
            //return Result;
        }
        
    }
}
