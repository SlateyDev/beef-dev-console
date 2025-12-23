using System;

namespace DevConsole;

[AttributeUsage(.Class | .Struct, .ReflectAttribute, ReflectUser=.StaticFields | .NonStaticFields, AlwaysIncludeUser=.AssumeInstantiated | .IncludeAllMethods)]
public struct DevConsoleCommandLibraryAttribute : Attribute
{
    public int data = 0;

    public this() {}

    public this(int data) {
        this.data = data;
    }
}

[AttributeUsage(.Method, .ReflectAttribute, ReflectUser=.Methods, AlwaysIncludeUser=.IncludeAllMethods)]
public struct DevConsoleCommandAttribute : Attribute
{
    public readonly String Name;
    public readonly String Description = null;

    public this(String name) {
        Name = name;
    }
}