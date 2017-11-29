using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.DirectoryServices.AccountManagement;
using System.DirectoryServices;
using VMware.Vim;
using System.Collections.Specialized;




namespace Change_Phone_numbers
{
    class Program
    {
        static void Main(string[] args)
        {
#region (Супер-пупер код)
            string[] readText = File.ReadAllLines("C:\\test\\Invalid_AD_Phone_Numbers.txt");
            //string sPattern = "\\d{8]-\\d{4}-\\d{4}-\\d{4}-\\d{12}";
            int i = 0;
            foreach (string line in readText)
            {
                int startID = line.IndexOf("\"");
                int endID = line.IndexOf("\'");
                string ID = line.Substring(startID + 1, endID - startID - 1);
                int endN = line.LastIndexOf("\"");
                int startN = line.LastIndexOf("\"", endN - 10);
                string N = line.Substring(startN + 1, endN - startN - 1);

                PrincipalContext ctx = new PrincipalContext(ContextType.Domain);
                UserPrincipal user = UserPrincipal.FindByIdentity(ctx, ID);

                if (user != null)
                {
                    var login = user.SamAccountName;
                    Console.WriteLine(login);
                }

                string number = string.Join("", N.ToCharArray().Where(Char.IsDigit));

                //string number = "";
                //foreach (char num in N)
                //if (char.IsDigit(num))
                //    number += num;

                if (number.Count() > 8)
                {
                    number = number.Substring(number.Count() - 9);
                    Console.WriteLine(ID + "\n" + String.Format("{0:+38 (0##) ### ## ##}", Convert.ToInt32(number)) + "\n" + ++i);
                }

            }

#endregion
            Console.WriteLine("Completed");
            Console.Read();
        }
    }
}
