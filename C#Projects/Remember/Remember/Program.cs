using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Remember
{
    class Program
    {
        static void Main(string[] args)
        {
            String day;
            Console.WriteLine("Enter pls day of week"); 
            day = Console.ReadLine();

            switch (day)
            {
                case "Mon": 
                case "Tues": 
                case "Wed": 
                case "Thur": 
                case "Fr": Console.WriteLine("Today is working day"); break;
                case "Sat": 
                case "Sun": Console.WriteLine("Today is weekend"); break;

                default: Console.WriteLine("Enter pls correct data"); break;
            }
            Console.ReadLine();
        }
    }
}
