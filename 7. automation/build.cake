Task("Build")
    .IsDependentOn("Restore-NuGet-Packages")
    .IsDependentOn("Version-Projects")
    .Does(() =>
{
    DotNetCoreBuild(sln, new DotNetCoreBuildSettings
    {
        Configuration = configuration
    });
});

Task("Generate-Documentation")
    .IsDependentOn("Generate-Code-Diagrams")
    .IsDependentOn("Generate-Database-Diagrams")
    .Does(() =>
{
    StartProcess("java", new ProcessSettings {
        Arguments = new ProcessArgumentBuilder()
            .Append("-jar ./docs/images/autogen/plantuml.jar")
            .Append("./docs/images/*.puml")
    });  
});

Task("Generate-Code-Diagrams")
    .Does(() =>
    {
        GenerateCodeUmlFromProject("src/Example", "domain");
        GenerateCodeUmlFromProject("src/Example/class1", "api");
    }
);

private void GenerateCodeUmlFromProject(string projectPath, string outputName)
{
     StartProcess("puml-gen", new ProcessSettings {
            Arguments = new ProcessArgumentBuilder()
                .Append(projectPath)
                .Append("docs/images/" + outputName)
                .Append("-dir")
                .Append("-public")
                .Append("-allInOne")
                .Append("-createAssociation")
                .Append("-excludePaths bin,obj,Properties")
        });
        CopyFile("docs/images/" + outputName + "/include.puml", "docs/images/" + outputName + ".puml");
        DeleteDirectory("docs/images/" + outputName, new DeleteDirectorySettings { Recursive = true });
}

Task("Generate-Database-Diagrams")
    .Does(() => {
       
     StartProcess("sqlcmd", new ProcessSettings {
            Arguments = new ProcessArgumentBuilder()
                .Append("-S localhost") // database server
                .Append("-d My-Database") // database name
                .Append("-i ./docs/images/autogen/generate-db-plantuml.sql") // sql file to execute
                .Append("-o ./docs/database.puml") // file to write output
                .Append("-I") // don't write updated row counts
                .Append("-h-1") // don't write headers
                .Append("-y 8000") // column width (needs to be large otherwise puml is truncated in file)
        });
    }
);



Task("Code-Coverage-Report")
    .IsDependentOn("Code-Coverage-Report-HtmlInline")
    .IsDependentOn("Code-Coverage-Report-Cobertura");

Task("Default")
    .IsDependentOn("Code-Coverage-Report")
    .IsDependentOn("Copy-Terraform-Artifacts")
    .IsDependentOn("Copy-Api-Artifacts");

Task("Publish-All")
    .IsDependentOn("Docker-Push")
    .IsDependentOn("Generate-Migrations");

RunTarget(target);