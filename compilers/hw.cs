using System;
using System.Text;

class HW {
    static void Main() {
        Console.OutputEncoding = Encoding.UTF8;
        Console.WriteLine("== Program in C# ==");
        for(int i = 2; i <= 7; ++i)
            Console.WriteLine($"The square of {i} is {i * i}");
    }
}
