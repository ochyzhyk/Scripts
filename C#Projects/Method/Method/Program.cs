using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Method
{
    class Program
    {
        static void Main(string[] args)
        {
            Animal Sobaka = new Animal();
            Animal Kot = new Animal();
            Sobaka.Run();


            for (int i = 0; i < 15; i++ )
                Sobaka.EstPohlobka();

            int vesSobaki = Sobaka.GetVes();
            Console.WriteLine("Вес нашей собаки: " + vesSobaki);
            Sobaka.Vesy();

            if (Sobaka.IsHealth())
                Console.WriteLine("Собака здорова");
            else
                Console.WriteLine("Собака не здорова");

            Console.ReadLine();
        }
    }
    class Animal
    {
        public string name;
        public int rost, vozrast;
        int ves;
        
        public void Run()
        {
            Console.WriteLine("Животное бежит");
        }
        void Obet()
        {
            ves += 1;
        }

        public void EstPohlobka()
        {
            Obet();
        }

        public void Vesy()
        {
            Console.WriteLine("Вес животного составляет {0} кг", ves);
        }

        public int GetVes()
        {
            return ves;

        }

        public bool IsHealth()
        {
            if (ves > 10)
                return false;
            else
                return true;
        }
    
    }
}
