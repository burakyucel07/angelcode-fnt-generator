# AngelCode .fnt File Generator
This standalone tool is made for Godot Engine projects. It's used for implementing bitmap fonts easier. It should work for any engine that uses .fnt files for its bitmap fonts, but it's only tested in Godot Engine projects. You have to download Godot Engine to build this tool. If you notice a bug or you have any suggestion, open an issue.

## Usage
![Tool instructions](/docs/instructions/fntgen-instructions.jpg?raw=true "Tool instructions")
1. Load the .png image using this button. You should be able to use other files too, like .bmp or .jpg even I haven't tested them yet.
2. Enter the name of the font. This is not the file name of the texture file. You don't have to use the same name with the texture name.
3. This is the file name of the texture file. For example, if you imported the "cool_font.png" file, the texture name is now "cool_font". You can't change this name using the tool. Exported .fnt file will be named as <texture_name>.fnt. For example, if your texture file name is "cool_font.png", your .fnt file will be named as "cool_font.fnt".
4. Enter the character dimensions (width and height). For example, if your character width is 12 and height is 22, enter these values and the tool will calculate how many characters are on the texture horizontally and vertically. In this example, the texture has 231 characters (including the zeroth character). Character boxes will be shown with green squares.
5. Enter the character base starting from the top.
6. Enter the characters in the same order with the texture file. For example, if your texture file has characters of "0123456789", you have to enter these characters in the characters list text area.
7. You can check the characters using this UI. Zoom in and out using mouse scroll.
8. You can see the current character from here. The transparent white part tells how much x advance you are setting to this character. You can check the advance amount using the UI shown in step 7.
9. Set the X Advance using the increase/decrease buttons. Also, you can enter a value but the value couldn't be bigger than the width of characters (You've set this in step 4).
10. You can switch to the next char or previous char using these controls. In the example, it says this texture has 231 characters (character index starts with 0) with the info you've given.
11. Export the .fnt file using this button. .fnt file will be exported to the same directory that the texture file is in. If there is a file with the same name, the tool will ask if you want to overwrite it.

## License
This project has MIT license. Godot Engine license: https://godotengine.org/license
