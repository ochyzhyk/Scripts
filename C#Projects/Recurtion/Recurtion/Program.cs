using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

class Program
    {
        static void Main()
        {
            bool x, y;

            Console.Write("Введите первое значение: ");
            x = Convert.ToBoolean(Console.ReadLine());

            Console.Write("Введите второе значение: ");
            y = Convert.ToBoolean(Console.ReadLine());
            
            SomeClass SC = new SomeClass();
            if (SC.First(x) & SC.Second(y)) { };
           
            Console.WriteLine("FIN");
            Console.ReadLine();
        }
    }

class SomeClass
{
    public bool First(bool first)
    {
        return first;
    }
    public bool Second(bool second)
    {
        return second;
    }
}