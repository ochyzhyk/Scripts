using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Method2
{
    class Program
    {
        static void Main()
        {
            Calc calc = new Calc();

            int first, second;
            Console.Write("Введите первое число: ");
            first = Convert.ToInt32(Console.ReadLine());

            Console.Write("Введите второе число: ");
            second = Convert.ToInt32(Console.ReadLine());
            
            Console.WriteLine("Сумма чисел составляет: {0}", calc.Sum(first,second));
            //Console.ReadLine();

            Console.WriteLine("Квадрат первого числа: {0}", calc.sq(first));
            Console.ReadLine();

        }
    }

    class Calc
    {
        public int Sum(int firstArg, int SecondArg)
        {
            return firstArg + SecondArg;
        }
        public int sq (int input)
        {
            return input * input;
        }
    }

}
