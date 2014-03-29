# Easy Lua

Easy Lua is the simplest way to add Lua scripts to your Adobe Flash or ActionScript project.
It builds on top of the excellent Lua port that ships with Adobe's open source [CrossBridge](https://github.com/adobe-flash/crossbridge) project.

#### Features

- Hides all the low level Lua C API details in one easy to use class.  No C knowledge required.
- Works with all ActionScript platforms (web, desktop, and mobile).
- Automatically converts Lua return values to ActionScript variables for easy interoperability.

## Installation

Installation is simple.
First, copy the files in the `src` and `lib` directories to your project.
Second, tell the compiler to link your code to `lib/lua.swc`.

## Usage

Create an instance of the `EasyLua` class:

    var easyLua:EasyLua = new EasyLua();

Call the `eval` method to execute some Lua code.  This code defines a `helloWorld` function that returns a string:

    easyLua.eval("function helloWorld() return 'hello world' end");

Call the function that we defined above and return the result back to ActionScript:

    var result:String = easyLua.eval("return helloWorld()");

You must explicity add the `return` keyword to tell Lua to return the value back to ActionScript.
Failure to do so will result in no value being returned.
This way you get to decide if you want to deal with the conversion overhead.
Most basic Lua types (nil, numbers, strings, booleans, and tables) are supported.
An exception will be raised if you try to return an unsupported type.
Tables will be automatically converted to either an AS3 array or object (hash) depending on if the keys are integers or strings.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
