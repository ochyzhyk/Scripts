using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace aduser
{
    class Program
    {
        static void Main(string[] args)
        {
            Work w1, w2, w3;

            w1 = new Work();
            w2 = new Work();
            w3 = new Work();

            w1.SetI(1);
            w2.SetI(2);
            w3.SetI(3);

            w1.SetJ(10);
            w2.SetJ(20);
            w3.SetJ(30);

            Console.WriteLine("w1.i = {0}, w2.i = {1}, w3.i = {2}", w1.i, w2.i, w3.i);
            Console.ReadLine();

            Console.WriteLine("Work.j = {0}", Work.j);
            Console.ReadLine();

            Work.SomeStaticMethod(40);
            Console.WriteLine("Work.j = {0}", Work.j);
            Console.ReadLine();

        }
    }

    class Work
    {
        public static int j;
        public int i;

        public static void SomeStaticMethod(int input)
        {
            j = input;
            Console.ReadLine();
        }


        public void SetJ(int j)
        {
            Work.j = j;
        }
        public void SetI(int i)
        {
            this.i = i;
        }
    }

}
