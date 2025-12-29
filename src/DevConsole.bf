using System;
using System.Collections;

namespace DevConsole;

public class DevConsole {
    private static Object _context;

    public delegate Object ParserDelegate(String inputString);

    public static void SetContext(Object context) {
        _context = context;
    }

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
        for (var typeDecl in Type.Types) {
            if (typeDecl.HasCustomAttribute<DevConsoleCommandLibraryAttribute>()) {
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
                    }
                    else {
                        Console.WriteLine($"Method ({method.Name}) is not decorated as [DevConsoleCommand()]. Skipping...");
                    }
                }

                /*for (var field in typeDecl.GetFields(.Public | .Instance | .NonPublic | .Static)) {
                    Console.WriteLine($"{field.FieldType.ToString(.. scope .())} {field.Name}");
                }*/
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
                }
                else if(captureStart == input[position]) {
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
            }
            else {
                args.Add(new $"{val}");
            }
            index++;
        } while(endPos < input.Length);
    }

    public static bool RunCommand(String input) {
        if (String.IsNullOrWhiteSpace(input)) return false;
        var commandName = new String();
        defer delete commandName;
        var commandArgs = new List<String>();
        defer {
            DeleteContainerAndItems!(commandArgs);
        }

        GetCommandFromString(input, commandName, commandArgs);

        (DevConsoleCommandAttribute attribute, System.Reflection.MethodInfo method) command;
        if(!commands.TryGetValue(commandName, out command)) {
            Console.WriteLine("Unknown command");
            return false;
        }
        
        if (command.method.IsStatic) {
            return ExecuteCommand(null, command, commandArgs);
        }
        if (_context != null && _context.GetType().IsSubtypeOf(command.method.DeclaringType)) {
            return ExecuteCommand(_context, command, commandArgs);
        }

        Console.WriteLine($"Invalid context for '{command.attribute.Name}', context needs to be instance of type '{command.method.DeclaringType.GetFullName(.. scope .())}'");
        //PrintError($"Invalid context for '{command.Value.commandName}', context needs to be instance of type '{command.Value.method.DeclaringType.FullName}'");
        return false;
    }

    /*private static string GetCommandUsage(string commandName, MethodBase method) {
        var paramUsage = _commands[commandName].attribute.Usage;
        if (string.IsNullOrWhiteSpace(paramUsage)) {
            paramUsage = string.Join(" ",
                method.GetParameters().Select(param =>
                    $"<{(param.IsDefined(typeof(ParamArrayAttribute)) ? "params " : "")}{param}>"));
        }

        return $"{commandName} [color=cyan]{paramUsage}[/color]";
    }
    
    private static void PrintUsage(string commandName, MethodBase method) {
        Print($"Usage: {GetCommandUsage(commandName, method)}");
    }*/

    private static bool ExecuteCommand(Object obj, (DevConsoleCommandAttribute attribute, System.Reflection.MethodInfo method) command, List<String> args) {
        //First we need to convert all the String params into the expected types to be sent to Invoke.
        /*for (var parameterIndex = 0; parameterIndex < command.method.ParamCount; parameterIndex++) {
            if (command.method.GetParamFlags(parameterIndex) == .Params) {
                var paramType = (System.Reflection.ArrayType)command.method.GetParamType(parameterIndex);
                var paramList = (Array)TrySilent!(paramType.CreateObject((int32)(args.Count - parameterIndex)));
                if (paramList == null) {
                    Console.WriteLine("ERR");
                    return false;
                }
                for (var argIndex = parameterIndex; argIndex < args.Count; argIndex++) {
                    if (TryParseParameter(command.method.GetParamType(parameterIndex).BaseType, (String)args[argIndex], var val)) {
                        //looks like i would need to do direct memory access to set a value
                        ((uint8*)Internal.UnsafeCastToPtr(paramList))[0] = val;
                        //paramList[argIndex - parameterIndex] = val;
                    }
                    else {
                        //PrintError($"Format Exception: Could not parse '{command.args[parameterIndex]}' as '{parameters[parameterIndex].ParameterType}'");
                        //PrintUsage(command.commandName, command.method);
                        return false;
                    }
                }
                //command.args = command.args.Take(parameterIndex).ToList();
                //command.args.Add(paramList.GetType().GetMethod("ToArray").Invoke(paramList, null));
            }
            /*else if (parameterIndex >= args.Count) {
                //Optional parameters. Not sure how to see this in BeefLang yet.
                if (command.method.GetParamType(parameterIndex)) {
                    args.Add(Type.Missing);
                }
                else {
                    //PrintError("Not enough arguments passed");
                    //PrintUsage(command.commandName, command.method);
                    return false;
                }
            }*/
            else {
                if (TryParseParameter(command.method.GetParamType(parameterIndex), (String)args[parameterIndex], var val)) {
                    args[parameterIndex] = val;
                }
                else {
                    //PrintError($"Format Exception: Could not parse '{command.args[parameterIndex]}' as '{parameters[parameterIndex].ParameterType}'");
                    //PrintUsage(command.commandName, command.method);
                    return false;
                }
            }
        }

        if (command.method.Invoke(obj, args) case .Ok) {
            return true;
        }
        else {
            //PrintError(ex.Message);
            //PrintUsage(command.commandName, command.method);
        }*/

        return false;
    }

    private static bool TryParseParameter(Type parameterType, String parameterString, out Object parsedValue){
        if (parameterType == typeof(String)) {
            parsedValue = parameterString;
            return true;
        }

        /*if (_parsers.ContainsKey(parameterType)) {
            parsedValue = _parsers[parameterType].Invoke(parameterString);
            return true;
        }
        else {
            var parseMethod = parameterType.GetMethod("Parse", new[]{ typeof(String) });

            if (parseMethod is not null) {
                try {
                    parsedValue = parseMethod.Invoke(null, new object[]{ parameterString });
                    return true;
                }
                catch {
                    parsedValue = null;
                    return false;
                    // throw new Exception($"Unable to parse parameter type: {parameterType}");
                }
            }
        }*/

        parsedValue = null;
        return false;
    }
}