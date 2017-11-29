using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace doWhile
{
    class Program
    {
        static void Main(string[] args)
        {
            bool quit = false;

            float first = 0;
            float second = 0;
            char operation = '\0';

            Console.WriteLine();
            Console.WriteLine("+ : сложение чисел");
            Console.WriteLine("- : разница чисел");
            Console.WriteLine("* : произведение чисел");
            Console.WriteLine("/ : отношение чисел");
            Console.WriteLine("q : выход из программы");
            Console.WriteLine();
            
            do 
            {
                try 
                {
                    Console.Write("Введите первое чило: ");
                    first = float.Parse(Console.ReadLine());

                    Console.Write("Введите второе чило: ");
                    second = float.Parse(Console.ReadLine());

                    Console.Write("Укажите операцию: ");
                    operation = char.Parse(Console.ReadLine());


                }
                catch
                {
                    Console.WriteLine("Внимательно читайте инструкцию");
                }

                switch (operation)
                {
                    case '+': Console.WriteLine("Сумма чисел составляет :" + (first + second));break;
                    case '-': Console.WriteLine("Разница чисел составляет :" + (first - second));break; 
                    case '*': Console.WriteLine("Произведение чисел составляет :" + (first * second));break;
                    case '/': Console.WriteLine("Отношение чисел составляет :" + (first / second));break;
                    case 'q': quit=true; break;
                }
            }
            while(!quit);
        }
    }
}
