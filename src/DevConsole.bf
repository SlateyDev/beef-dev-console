using System;
using System.Collections;

namespace DevConsole;

public class DevConsole
{
    public delegate Object ParserDelegate(String inputString);

    private static Dictionary<Type, ParserDelegate> _parsers = new .() {
        (
            typeof(DateTime),
            (ParserDelegate)scope (s) => {
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

    private static int GetNextString(String input, int position, String output) {
        var position;
        char8 captureStart = 0;

        while(input[position].IsWhiteSpace && position < input.Length) position++;

        while(position < input.Length && !(input[position].IsWhiteSpace && captureStart == 0)) {
            if(input[position] == '\"' || input[position] == '\'') {
                if(captureStart == 0) {
                    captureStart = input[position];
                    position++;
                    continue;
                } else if(captureStart == input[position]) {
                    captureStart = 0;
                    position++;
                    continue;
                }
            }
            output.Append(input[position]);
            position++;
        }

        while(position < input.Length && input[position].IsWhiteSpace) position++;

        return position;
    }

    public static void GetCommandFromString(String input, String commandName, List<String> args) {
        var index = 0;

        input.Trim();

        var startPos = 0;
        var endPos = 0;
        repeat {
            var val = scope String();
            endPos = GetNextString(input, startPos, val);
            startPos = endPos;

            if(index == 0) {
                commandName.Set(val);
            } else {
                args.Add(new $"{val}");
            }
            index++;
        } while(endPos < input.Length);
    }

/*    public static bool RunCommand(string input)
    {
        if (string.IsNullOrWhiteSpace(input)) return false;
        var command = GetCommandFromString(input);
        if (command is null)
        {
            PrintError("Unknown command");
            return false;
        }
        
        if (command.Value.method.IsStatic)
        {
            return ExecuteCommand(null, command.Value);
        }

        if (command.Value.method.DeclaringType!.IsInstanceOfType(_context))
        {
            return ExecuteCommand(_context, command.Value);
        }

        PrintError($"Invalid context for '{command.Value.commandName}', context needs to be instance of type '{command.Value.method.DeclaringType.FullName}'");
        return false;
    }

    private static string GetCommandUsage(string commandName, MethodBase method)
    {
        var paramUsage = _commands[commandName].attribute.Usage;
        if (string.IsNullOrWhiteSpace(paramUsage))
        {
            paramUsage = string.Join(" ",
                method.GetParameters().Select(param =>
                    $"<{(param.IsDefined(typeof(ParamArrayAttribute)) ? "params " : "")}{param}>"));
        }

        return $"{commandName} [color=cyan]{paramUsage}[/color]";
    }
    
    private static void PrintUsage(string commandName, MethodBase method)
    {
        Print($"Usage: {GetCommandUsage(commandName, method)}");
    }

    private static bool ExecuteCommand(object obj, (string commandName, MethodBase method, List<object> args) command)
    {
        var parameters = command.method.GetParameters();
        for (var parameterIndex = 0; parameterIndex < parameters.Length; parameterIndex++)
        {
            if (parameters[parameterIndex].IsDefined(typeof(ParamArrayAttribute), false))
            {
                var paramList = Activator.CreateInstance(typeof(List<>).MakeGenericType(parameters[parameterIndex].ParameterType.GetElementType()!));
                for (var argIndex = parameterIndex; argIndex < command.args.Count; argIndex++)
                {
                    if (TryParseParameter(parameters[parameterIndex].ParameterType.GetElementType(), (string)command.args[argIndex],
                            out var val))
                    {
                        paramList.GetType().GetMethod("Add").Invoke(paramList, new[] { val });
                        // command.args[argIndex] = val;
                    }
                    else
                    {
                        PrintError($"Format Exception: Could not parse '{command.args[parameterIndex]}' as '{parameters[parameterIndex].ParameterType}'");
                        PrintUsage(command.commandName, command.method);
                        return false;
                    }
                }
                command.args = command.args.Take(parameterIndex).ToList();
                command.args.Add(paramList.GetType().GetMethod("ToArray").Invoke(paramList, null));
            }
            else if (parameterIndex >= command.args.Count)
            {
                if (parameters[parameterIndex].IsOptional)
                {
                    command.args.Add(Type.Missing);
                }
                else
                {
                    PrintError("Not enough arguments passed");
                    PrintUsage(command.commandName, command.method);
                    return false;
                }
            }
            else
            {
                if (TryParseParameter(parameters[parameterIndex].ParameterType, (string)command.args[parameterIndex], out var val))
                {
                    command.args[parameterIndex] = val;
                }
                else
                {
                    PrintError($"Format Exception: Could not parse '{command.args[parameterIndex]}' as '{parameters[parameterIndex].ParameterType}'");
                    PrintUsage(command.commandName, command.method);
                    return false;
                }
            }
        }
        try
        {
            command.method.Invoke(obj, command.args.ToArray());
            return true;
        }
        catch (Exception ex)
        {
            PrintError(ex.Message);
            PrintUsage(command.commandName, command.method);
        }

        return false;
    }

    private static bool TryParseParameter(Type parameterType, string parameterString, out object parsedValue){
        if (parameterType == typeof(string)){
            parsedValue = parameterString;
            return true;
        }

        if (_parsers.ContainsKey(parameterType))
        {
            try{
                parsedValue = _parsers[parameterType].Invoke(parameterString);
                return true;
            }
            catch
            {
                parsedValue = null;
                return false;
                // throw new Exception($"Unable to parse parameter type: {parameterType}");
            }
        }
        else
        {
            var parseMethod = parameterType.GetMethod("Parse", new[]{ typeof(string) });

            if (parseMethod is not null){
                try{
                    parsedValue = parseMethod.Invoke(null, new object[]{ parameterString });
                    return true;
                }
                catch
                {
                    parsedValue = null;
                    return false;
                    // throw new Exception($"Unable to parse parameter type: {parameterType}");
                }
            }
        }

        parsedValue = null;
        return false;
    }*/
}