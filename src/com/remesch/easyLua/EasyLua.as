package com.remesch.easyLua
{
  import flash.utils.ByteArray;

  import sample.lua.CModule;
  import sample.lua.__lua_objrefs;

  public class EasyLua
  {
    //
    // Instance variables.
    //

    protected var _luaState:int;
    protected var _autoConvertArrays:Boolean = true;

    //
    // Constructor.
    //

    public function EasyLua() {
      _luaState = Lua.luaL_newstate();
      Lua.luaL_openlibs(_luaState);
    }

    //
    // Public static methods.
    //

    public static function addFile(name:String, bytes:ByteArray):void {
      CModule.vfs.addFile(name, bytes);
    }

    public static function addAssetAsFile(name:String, klass:Class):void {
      addFile(name, (new klass as ByteArray));
    }

    //
    // Public instance methods.
    //

    public function get autoConvertArrays():Boolean { return _autoConvertArrays; }
    public function set autoConvertArrays(val:Boolean):void { _autoConvertArrays = val; }

    public function dispose():void {
      Lua.lua_close(_luaState);
    }

    public function eval(code:String):* {
      var error:int;
      var top:int = Lua.lua_gettop(_luaState);
      var result:*;

      clearStack();

      error = Lua.luaL_loadstring(_luaState, code);

      if (error)
        throw new Error('Unable to read code (possible syntax errors).');

      error = Lua.lua_pcallk(_luaState, 0, Lua.LUA_MULTRET, 0, 0, null);

      if (error)
        throw new Error("Failed to run code: " +  Lua.lua_tolstring(_luaState, -1, 0));

      result = resultsToAs3(top);

      // IMPORTANT: Force the garbage collector to run after each eval().
      // Easy Lua is designed to make working with AS3 + Lua as easy as possible.
      // By collecting garbage after every eval(), I hope to prevent inefficient Lua
      // scripts from hogging memory (especially on mobile devices).
      Lua.lua_gc(_luaState, Lua.LUA_GCCOLLECT, 0);

      return result;
    }

    public function evalEmbedded(klass:Class):* {
      var code:String = (new klass as ByteArray).toString();
      var result:* = eval(code);

      return result;
    }

    public function toLuaString(object:*):String {
      var result:String = '';

      if(object is String) {
        result += '"';
        result += object.replace(/\"/g, "\"");
        result += '"';
      }
      else if(object == null) {
        result = 'nil';
      }
      else if((object is Number) || (object is int) || (object is uint)) {
        result = object.toString();
      }
      else if(object is Boolean) {
        result = object.toString();
      }
      else if(object is Array) {
        result = '{';
        var length:int = object.length;
        for(var i:int = 0; i < length; i++) {
          result += toLuaString(object[i]);
          result += ','
        }
        result += '}';
      }
      else if (object is Object) {
        result = '{';
        for(var key:* in object) {
          if(!(key is String))
            throw new Error('Unable to convert non-string Object key to Lua string.');
          result += key;
          result += '=';
          result += toLuaString(object[key]);
          result += ','
        }
        result += '}';
      }
      else
        throw new Error('Unable to convert unsupported object type to Lua string.');

      return result;
    }

    public function evalFunction(name:String, ... args):* {
      var result:*;
      var argsLen:int = args.length;
      var evalString:String = 'return ' + name + '(';

      for (var i:int = 0; i < argsLen; i++) {
        evalString += toLuaString(args[i]);
        if(i + 1 < argsLen)
          evalString += ',';
      }
      evalString += ')';

      result = eval(evalString);

      return result;
    }

    // Advanced: Expose an AS3 object directly to Lua as a global variable.
    /*
    public function exposeAsGlobal(name:String, object:*):void {
      var udptr:int = Lua.push_flashref(_luaState)
      sample.lua.__lua_objrefs[udptr] = object;
      Lua.lua_setglobal(_luaState, name);
    }
    */

    //
    // Protected methods (subclass and override as necessary).
    //

    protected function resultsToAs3(bottom:int=0):* {
      var top:int = Lua.lua_gettop(_luaState);
      var result:*;

      // No return value.
      if(top == 0)
        return null;

      // Single return value.
      if((top - bottom) == 1) {
        result = variableToAs3(top);
        Lua.lua_pop(_luaState, 1);
        return result;
      }

      // Multiple return values.
      result = new Array();
      while(top > bottom) {
        var r:* = variableToAs3(top);
        result.push(r);
        Lua.lua_pop(_luaState, 1);
        top -= 1;
      }
      result.reverse();
      return result;
    }

    protected function variableToAs3(index:int):* {
      var result:*;

      switch(Lua.lua_type(_luaState, index)) {
        case Lua.LUA_TSTRING:
          result = stringToAs3(index);
          break;
        case Lua.LUA_TBOOLEAN:
          result = booleanToAs3(index);
          break;
        case Lua.LUA_TNUMBER:
          result = numberToAs3(index);
          break;
        case Lua.LUA_TNIL:
          result = nilToAs3(index);
          break;
        case Lua.LUA_TTABLE:
          result = tableToAs3(index);
          break;
        default:
          throw new Error('Your Lua code returned an unsupported data type.');
      }

      return result;
    }

    protected function clearStack():void {
      var top:int = Lua.lua_gettop(_luaState);
      Lua.lua_pop(_luaState, top);
    }

    protected function stringToAs3(index:int):String {
      return Lua.lua_tolstring(_luaState, index, null);
    }

    protected function booleanToAs3(index):Boolean {
      return !!Lua.lua_toboolean(_luaState, index);
    }

    protected function numberToAs3(index):Number {
      return Lua.lua_tonumberx(_luaState, index, 0);
    }

    protected function nilToAs3(index):Object {
      return null;
    }

    protected function tableToAs3(index:int):Object {
      var result:Object = {};
      var top:int;
      var key:*;
      var value:*;
      var convertedResult:Array;

      Lua.lua_pushnil(_luaState);
      while(Lua.lua_next(_luaState, index) != 0) {
        top = Lua.lua_gettop(_luaState);
        key = variableToAs3(top - 1);
        value = variableToAs3(top);
        result[key] = value;
        Lua.lua_pop(_luaState, 1);
      }

      if(_autoConvertArrays) {
        convertedResult = convertObjectToArray(result);
        if(convertedResult)
          return convertedResult;
      }

      return result;
    }

    protected function convertObjectToArray(object:Object):Array {
      var result:Array = new Array();

      for(var key:* in object) {
        if(key is int)
          result[key - 1] = object[key];
        else
          return null;
      }

      return result;
    }
  }
}