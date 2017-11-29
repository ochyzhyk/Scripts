using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace _while
{
    class Program
    {
        static void Main(string[] args)
        {
            string first, second;
            while (true)
            {
                Console.Write("Enter first number: ");
                first=Console.ReadLine();
                if (first == "q")
                    break;

                Console.Write("Enter second number: ");
                second=Console.ReadLine();
                if (second == "q")
                    break;
                
                if (int.Parse(second) == 0)
                {
                    Console.WriteLine("not true"); 
                }
                try
                {
                    Console.WriteLine(first + " / " + second + " = " + 
                                      float.Parse(first) / float.Parse(second));
                    Console.ReadLine();
                }
                catch
                {
                    Console.WriteLine("For exit press 'q'");
                }


            }
        }      
    }
}
