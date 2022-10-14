# Diagrams as code #

## To view the plantuml examples in Visual Studio Code ##

* Install the plantuml docker container

```docker run -d -p 8080:8080 plantuml/plantuml-server:jetty```

* Install the plantuml VS Code extension 

```code --install-extension jebbs.plantuml```

* While editing the *.puml file, type `Alt + D` to open a preview window containing the diagram

## To work with the Mermaid example locally ##

* Install the Visual Studio Markdown preview extension:

```code --install-extension  bierner.markdown-mermaid```

* While editing the *.md file, type `Shift + Option + V` to open a preview window containing the diagram


## To work with the Structurizr example locally ##

* Install the Visual Studio Dev Containers extension

```code --install-extension ms-vscode-remote.remote-containers```

* Open the "6. structurizr" folder in a VS Code instance, it should recognise the dev container configuration and offer to re-open as a container instance