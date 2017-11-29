using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using System.Diagnostics;
using System.Threading;



namespace web
{
    class Program
    {
        static void Main(string[] args)
        {
            do
            {

                string[] linkarray = new string[] 
                {
                    "https://it.dc.local",
                    "https://project-miscellanea.dc.local",
                    "https://ifrs-2012.dc.local",
                    "https://ifrs-2013.dc.local",
                    "https://ifrs-2014.dc.local",
                    "https://ifrs-2015.dc.local",
                    "https://ifrs-2016.dc.local",
                    "https://hr.dc.local",
                    "https://sea-port.dc.local",
                    "http://dataroom.dc.local",
                    "http://documents.dc.local",
                    "http://project-budgeting.dc.local",
                    "https://mysites.dc.local",
                    "https://project-development.dc.local",
                    "http://project-treasury.dc.local",
                    "https://global-search.dc.local"
                };

                foreach (string link in linkarray)
                {
                    try
                    {
                        Check(link);
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(ex.ToString());
                    }
                }
            } 
            while (true);


        }

        static void Check (string inlink)
        {
            WebClient client = new WebClient();
            client.Credentials = CredentialCache.DefaultCredentials;

            TimeSpan sec = TimeSpan.Parse("00:00:01.000");

            Stopwatch timer = new Stopwatch();
            timer.Start();

            string reply = client.DownloadString(inlink);

            timer.Stop();

            TimeSpan timeTaken = timer.Elapsed;

            if (timeTaken > sec)
                Console.WriteLine("\nFREEZE " + "\n" + timeTaken + "\n" + (DateTime.Now.ToString("h:mm:ss tt")) + "\n" + inlink + "\n");
            else
               Console.WriteLine("\nOK" + "\n" + inlink + "\n" + timeTaken);
            //Console.Read();

            Thread.Sleep(1000);
        }

    }
}
