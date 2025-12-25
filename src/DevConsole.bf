using System;
using System.Collections;

namespace DevConsole;

public class DevConsole
{
    public delegate Object ParserDelegate(String inputString);

    private static Dictionary<Type, ParserDelegate> _parsers = new .() {
        (
            typeof(DateTime),
            (ParserDelegate)new (s) => {
                Console.WriteLine("TEST");
                return null;
            }
        ),
        /*(
            typeof(Node),
            (ParserDelegate)new (inputString) => _context.GetNodeOrNull(inputString)
        ),
        (
            typeof(Vector2), (ParserDelegate)new (inputString) =>
            {
                var amounts = inputString.TrimStart('(').TrimEnd(')').Split(",").Select(val => val.Trim()).ToArray();
                if (amounts.Length != 3) return null;
                return new Vector3(float.Parse(amounts[0]), float.Parse(amounts[1]), float.Parse(amounts[2]));
            }
        ),
        (
            typeof(Vector3), (ParserDelegate)new (inputString) =>
            {
                var amounts = vectorString.TrimStart('(').TrimEnd(')').Split(",").Select(val => val.Trim()).ToArray();
                if (amounts.Length != 2) return null;
                return new Vector2(float.Parse(amounts[0]), float.Parse(amounts[1]));
            }
        )*/
    } ~ delete _;

    private const StringView CommandPattern = "(?<val>(\\([^\\)]+\\)))|\"(?<val>[^\"]+)\"|'(?<val>[^']+)'|(?<val>[^\\s]+)";

    private static Dictionary<String, (DevConsoleCommandAttribute attribute, System.Reflection.MethodInfo method)> commands = new .() ~ delete _;

    public static void GetCommands() {
        for (var typeDecl in Type.Types)
        {
            if (typeDecl.HasCustomAttribute<DevConsoleCommandLibraryAttribute>())
            {
                Console.WriteLine($"Found DevConsoleCommandLibrary: {typeDecl.GetFullName(.. scope .())}");

                for (var method in typeDecl.GetMethods()) {
                    if (method.GetCustomAttribute<DevConsoleCommandAttribute>() case .Ok(var methodAttrib)) {
                        var nameExists = false;
                        for (var command in commands) {
                            if (command.key == methodAttrib.Name) {
                                nameExists = true;
                                continue;
                            }
                        }
                        if (nameExists) {
                            Console.WriteLine($"Method ({methodAttrib.Name}) already in collection. Skipping...");
                            continue;
                        }
                        commands.Add(methodAttrib.Name, (methodAttrib, method));

                        Console.WriteLine($"Adding method ({methodAttrib.Name}) to collection");

                        Console.WriteLine(GetCommandUsage(methodAttrib.Name, .. scope .()));
                    } else {
                        Console.WriteLine($"Method ({method.Name}) is not decorated as [DevConsoleCommand()]. Skipping...");
                    }
                }

                for (var field in typeDecl.GetFields(.Public | .Instance | .NonPublic | .Static)) {
                    Console.WriteLine($"{field.FieldType.ToString(.. scope .())} {field.Name}");
                }
            }
        }
    }

    public static void GetCommandUsage(String commandName, String usageResponse) {
        var method = commands[commandName].method;

        if (method.IsPublic) usageResponse.Append("public ");
        if (method.IsStatic) usageResponse.Append("static ");
        usageResponse.AppendF($"{method.ReturnType.ToString(.. scope .())} ");
        usageResponse.AppendF(scope $"{commandName}(");
        for (var paramIndex < method.ParamCount) {
            usageResponse.AppendF($"{paramIndex > 0 ? ", ": ""}{method.GetParamFlags(paramIndex) == .Params ? "params " : ""}{method.GetParamType(paramIndex).ToString(.. scope .())} {method.GetParamName(paramIndex)}");
        }
        usageResponse.Append(")");
    }
}