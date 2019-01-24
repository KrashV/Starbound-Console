# Starbound-Console
A GUI mod for running lua scripts in the game

# Prerequirements
* [QuickBar Mini](https://github.com/Silverfeelin/Starbound-Quickbar-Mini "Starbound-QuickBar-Mini")
* Disabled safe scripts
   ``/Starbound/storage/starbound.config: "safeScripts": false``

# Usage
Locate the Console icon in the QuickBar-Mini menu:
![QuickBar preview](https://i.imgur.com/Q7tA1J2.png)

## Working with the console
![Console preview](https://i.imgur.com/F3qFiZo.png)

1. Text area

   There will be displayed the lines you have been inserted in the lineCode textbox (look below). You can manually edit the lines by pressing on them: the selected line will appear in the lineCode textbox. You can also delete lines by pressing the small X icon at the right border of the screen.
2. lineCode textbox

   This is the place you actually write the code for the following inserting. This line also handles the edition of the code, as well as saving and loading functionality (see below)
3. Return label

   The result of the script will be printed in this area. If an error occured, the stack trace will be printed instead; the line with the error will be highlighted in the text area.
4. Controls

   * Run button
   
      Runs the script. The result of the eval will be printed in the Return label.
   * Clear button
   
      Clears the text area
   * Load button
   
      Loads the file into the text area. The path to the file is read from the lineCode textbox and must either be absolute or relative. In relative scenario, the files are searched from the same directory the game is running at. (i.e. /Starbound/win32)
   * Save button
   
      Saves the files from the text area. The path to the file is read from the lineCode textbox and must either be absolute or relative. In relative scenario, the file will be placed at the same directory the game is running at. (i.e. /Starbound/win32)
      
 ## Accessing more functionality
 
 If you want to have an access to stuff like ``tech`` or ``activeItem``, add the following messageHandlers to the tech or activeItem scripts:

 ```lua
function can_call(module, func)
   if module and func then return not not (_ENV[module] and _ENV[module][func])
   elseif module then return not not _ENV[module] 
   end 
   return false
end

function call_fn(module, func, ...)
   if can_call(module, func) and func then 
      return _ENV[module][func](...)
   end
end
```

In the init, add the following handlers:

Tech script:

```lua
  message.setHandler("can_callTech", localHandler(can_call))
  message.setHandler("call_fnTech", localHandler(call_fn))
```

ActiveItem script:

```lua
  message.setHandler("can_callItem", localHandler(can_call))
  message.setHandler("call_fnItem", localHandler(call_fn))
```

Obviously, you should have the tech installed on your character and have an active item with the handlers in your hands.
