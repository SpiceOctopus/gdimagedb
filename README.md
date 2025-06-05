# Notice
This repository is frozen.
Development continues on [codeberg](https://codeberg.org/SpaceOctopus/gdimagedb)

## GDImageDB
A simple media database implemented with godot.

## Supported media formats
The supported formats can be found (and modified) in the src/settings.gd file.  
Currently the following formats are supported:  
Image files: jpg/jpeg, png, webp, bmp, gif / animated gif  
Video files: ogv, mp4, webm, mov, avi

## Organization and Coding guidelines
The project (mostly) follows the official godot guidelines.  
[Organization guideline](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)  
[GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

## How to build
Download [Godot engine](https://godotengine.org/) version 4.3.  
Import the src/project.godot file via the godot project manager.  
After opening the project, you can now press 'F5' to build and start debugging.

To build an executable for release or external debugging:
Under 'Projects' -> 'Export', add the fitting export profile for your system and download the toolchain as prompted.  
Check the 'Embed PCK' option.  
You can now build the project with the 'Export Project' button.

## Rendering the icons
Download [Blender](https://www.blender.org/) min. version 4.2.  
Open the respective .blend files and press F12 to start the rendering process.

## Addon Licenses
The files in the src/addons folder are not subject to the project's license.  
Each addon includes its own license.

## Resource Licenses
The files in the resources folder are licensed according to the accompanying license files.
