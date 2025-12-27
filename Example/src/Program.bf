using System;
using System.Collections;
using DevConsole;

namespace Example;

class Program
{
    static mixin CreateScopedObject(System.Type type) {
        Object obj = null;
        if (let result = type.CreateObject())
        {
            obj = result;
            defer:mixin delete obj;
        }
        obj
    }
    static void PrintCommandAndArgs(String command, List<String> args) {
        Console.WriteLine($"Command: {command}");
        for(var arg in args) {
            Console.WriteLine($" - {arg}");
        }
    }
    static int Main(String[] args) {
        DevConsole.GetCommands();

        var commandName = new String();
        defer delete commandName;
        var commandArgs = new List<String>();
        defer {DeleteContainerAndItems!(commandArgs);}

        DevConsole.GetCommandFromString("print test", commandName, commandArgs);
        PrintCommandAndArgs(commandName, commandArgs);

        ClearAndDeleteItems!(commandArgs);

        DevConsole.GetCommandFromString("hooley \"dooley\" wef", commandName, commandArgs);
        PrintCommandAndArgs(commandName, commandArgs);

        ClearAndDeleteItems!(commandArgs);

        DevConsole.GetCommandFromString("hooley 'dooley' wef", commandName, commandArgs);
        PrintCommandAndArgs(commandName, commandArgs);

        ClearAndDeleteItems!(commandArgs);

        DevConsole.GetCommandFromString("hooley 'do\"ol\"ey' wef", commandName, commandArgs);
        PrintCommandAndArgs(commandName, commandArgs);

        ClearAndDeleteItems!(commandArgs);

        DevConsole.GetCommandFromString("hooley do\"ol\"ey wef", commandName, commandArgs);
        PrintCommandAndArgs(commandName, commandArgs);

        for (var typeDecl in Type.Types)
        {
            if (typeDecl.GetCustomAttribute<DevConsoleCommandLibraryAttribute>() case .Ok(var attrib))
            {
                Console.WriteLine($"Attribute data = {attrib.data}");

                if (typeDecl.GetMethod("Print") case .Ok(var m)) {
                    Console.WriteLine(m.GetType());

                    let methodParams = scope Object[2] (
                        20,
                        "A nice string message",
                    );
                    if (m.Invoke(null, params methodParams) case .Ok) {}
                }

                let obj = CreateScopedObject!(typeDecl);

                if (typeDecl.GetMethod("ChangeIdentifier") case .Ok(var method)) {
                    if (method.Invoke(obj, 14) case .Ok(var _)) {
                    }
                } else {
                    Console.WriteLine("Method not found");
                }

                if (typeDecl.GetField("mIdentifier") case .Ok(var field)) {
                    if (field.GetValue<int>(obj) case .Ok(var value)) {
                        Runtime.Assert(value == 14);
                    }
                } else {
                    Console.WriteLine("Field not found");
                }
            }
        }

        //InvokeFuncs();

        return 0;
    }

    /*static void InvokeFuncs()
    {
        /* Invoke member methods */
        {
            let mh = scope MethodHolder();

            /* Pass 'mh' as 'target', as well as method our parameters. Note that we don't handle any errors */
            using (Variant _ = typeof(MethodHolder).GetMethod("ChangeIdentifier").Get().Invoke(mh, 14)) {}

            Runtime.Assert(mh.mIdentifier == 14);
        }

        /* Invoke all static methods */
        int passInt = 8;
        for (let m in typeof(MethodHolder).GetMethods(.Static))
        PARAMS:
        {
            /* Pass params based on what the function takes */
            let methodParams = scope Object[m.ParamCount];
            for (let i < m.ParamCount)
            {
                Object param;
                switch (m.GetParamType(i)) /* This covers all the cases in this example */
                {
                case typeof(String):
                    param = "A nice string message";
                case typeof(int):

                    /* We need to box this value into an object ourselves to make sure it's not out of scope and deleted when we invoke the method */
                    /* param = passInt; would implicitly box passInt, but be deleted once we leave this 'for (let i < m.ParamCount)' loop cycle */
                    /* where as we need it to persist the outer "method" loop's cycle to be valid at the Invoke() call */
                    param = scope:PARAMS box passInt;
                default:
                    param = null;
                }

                methodParams[i] = param;
            }

            /* Invoke the method and handle the result / return value. Static methods don't have a target */
            /* Note that 'Invoke(null, methodParams)' would attempt to pass the Object[] as the only argument */
            switch (m.Invoke(null, params methodParams))
            {
            case .Ok(let val):

                /* Handle returned int variants */
                if (val.VariantType == typeof(int))
                {
                    let num = val.Get<int>();
                    Console.WriteLine($"Method {m.Name} returned {num}");
                }

            case .Err:
                Console.WriteLine($"Couldn't invoke method {m.Name}");
            }
        }
    }*/
}

[DevConsoleCommandLibrary(1337)]
class MethodHolder
{
    public int mIdentifier;

    static int GiveMeFive()
    {
        return 5;
    }

    [DevConsoleCommand("print")]
    public static void Print(int num, String message)
    {
        Console.WriteLine($"{num}: {message}");
    }

    [DevConsoleCommand("change")]
    public void ChangeIdentifier(int newIdent)
    {
        mIdentifier = newIdent;
        Console.WriteLine($"I am now number {newIdent}");
    }
}