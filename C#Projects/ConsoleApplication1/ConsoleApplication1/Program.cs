using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApplication1
{
    class Program
    {
        static void Main()
        {
            byte a = 20;
            byte b = 30;
            byte c;

            c = (a > b) ? a : b;


            Console.WriteLine("var c contains value: " + c);
            Console.Read();
        }
    }
}
