using System;
using DevConsole;

namespace Example;

[DevConsoleCommandLibrary]
class TestCommands
{
    [DevConsoleCommand("print")]
    public static void Print(int num, String message)
    {
        Console.WriteLine($"{num}: {message}");
    }

    [DevConsoleCommand("blah")]
    public static void Blah(int num, params String[] message)
    {
        Console.WriteLine($"{num}: {message}");
    }
}

