using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace jaggedarray
{
    class Program
    {
        static void Main(string[] args)
        {
            int[][] jarray = new int[2][];

            int[] arraya = new int[] { 5, 65, 211, 1156, 11 };
            int[] arrayb = new int[] { 2, 3, 5, 7 };

            foreach (int a in arraya)
            {
                string result = "";
                foreach (int b in arrayb)
                {
                    int c = a % b;
                    result = result + c.ToString();  
                }
                if (!(result.Contains("0")))
                    Console.WriteLine("Integer {0} is prime integer", a);
               
            }
            Console.ReadLine();
        }

    }
}
