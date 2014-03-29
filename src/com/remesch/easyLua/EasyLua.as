package com.remesch.easyLua
{
  import flash.utils.ByteArray;

  public class EasyLua
  {
    //
    // Instance variables.
    //

    protected var _luaState:int;

    //
    // Constructor.
    //

    public function EasyLua() {
      _luaState = Lua.luaL_newstate();
      Lua.luaL_openlibs(_luaState);
    }

    //
    // Public methods.
    //

    public function dispose():void {
      Lua.lua_close(_luaState);
    }

    public function eval(code:String):* {
      var error:int;

      clearStack();

      error = Lua.luaL_loadstring(_luaState, code);

      if (error)
        throw new Error('Unable to read code (possible syntax errors)');

      error = Lua.lua_pcallk(_luaState, 0, Lua.LUA_MULTRET, 0, 0, null);

      if (error)
        throw new Error("Failed to run code: " +  Lua.lua_tolstring(_luaState, -1, 0));

      return resultsToAs3();
    }

    public function evalEmbedded(klass:Class):* {
      return eval((new klass as ByteArray).toString());
    }

    //
    // Protected methods (subclass and override as necessary).
    //

    protected function resultsToAs3(bottom:int=1):* {
      var top:int = Lua.lua_gettop(_luaState);
      var result:*;

      trace("Top: " + top.toString());
      trace("Bottom: " + bottom.toString());

      // No return value.
      if(top == 0)
        return null;

      // Single return value.
      if(top == bottom) {
        result = variableToAs3(top);
        Lua.lua_pop(_luaState, 1);
        return result;
      }

      // Multiple return values.
      result = new Array();
      while(top >= bottom) {
        var r:* = variableToAs3(top);
        result.push(r);
        Lua.lua_pop(_luaState, 1);
        top -= 1;
      }
      result.reverse();
      return result;
    }

    protected function variableToAs3(index:int):* {
      switch(Lua.lua_type(_luaState, index)) {
        case Lua.LUA_TSTRING:
          return stringToAs3(index);
        case Lua.LUA_TBOOLEAN:
          return booleanToAs3(index);
        case Lua.LUA_TNUMBER:
          return numberToAs3(index);
        case Lua.LUA_TNIL:
          return nilToAs3(index);
        case Lua.LUA_TTABLE:
          return tableToAs3(index);
          break;
        default:
          throw new Error('Your Lua code returned unsupported data type');
      }
    }

    protected function clearStack():void {
    }

    protected function stringToAs3(index:int):String {
      return Lua.lua_tolstring(_luaState, index, null);
    }

    protected function booleanToAs3(index):Boolean {
      return !!Lua.lua_toboolean(_luaState, index);
    }

    protected function numberToAs3(index):Number {
      return Lua.lua_tonumberx(_luaState, -1, 0);
    }

    protected function nilToAs3(index):Object {
      return null;
    }

    protected function tableToAs3(index:int):Object {
      var result:Object = {};

      return result;
    }
  }
}