using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace StaticMethod
{
    class Program
    {
        static void Main(string[] args)
        {
            Animal a1, a2;
            a1 = new Animal("Колли");
            a2 = new Animal("Перс");

            Console.WriteLine("a1.poroda = {0}, a1.rost = {1}, a1.wes = {2}", a1.poroda, a1.rost, a1.wes);
            a1.ShowPlaneta();
            Console.WriteLine("a2.poroda = {0}, a2.rost = {1}, a2.wes = {2}", a2.poroda, a2.rost, a2.wes);
            a2.ShowPlaneta();
            Console.ReadLine();
        }
    }

    class Animal
    {
        public int rost;
        public string poroda;
        public int wes;

        public static string Planeta;

        public void Eda (int pohlobka)
        {
            wes += pohlobka;
        }

        public Animal()
        {
        }

        public Animal (string poroda)
        {
            this.poroda = poroda;
        }

       static Animal()
        {
            Planeta = "Земля";
        }

        public void ShowPlaneta()
        {
            Console.WriteLine(Planeta);
        }
    }
}
