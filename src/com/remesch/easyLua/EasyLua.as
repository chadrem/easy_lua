package com.remesch.easyLua
{
  import flash.utils.ByteArray;

  public class EasyLua
  {
    //
    // Instance variables.
    //

    private var _luaState:int;

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
    // Private methods.
    //

    private function resultsToAs3(bottom:int=1):* {
      var top:int = Lua.lua_gettop(_luaState);

      if(top == 0)
        return undefined;

      if(top == bottom)
        return entryToAs3(top);

      var result:Array = [];

      for(var i:int = bottom; i <= top; i++) {
      }

      return result;
    }

    private function entryToAs3(index:int):* {
      switch(Lua.lua_type(_luaState, index)) {
        case Lua.LUA_TSTRING:
          return Lua.lua_tolstring(_luaState, index, null);
        case Lua.LUA_TBOOLEAN:
          return !!Lua.lua_toboolean(_luaState, index);
        case Lua.LUA_TNUMBER:
          return Lua.lua_tonumberx(_luaState, -1, 0);
        case Lua.LUA_TNIL:
          return null;
        case Lua.LUA_TTABLE:
          throw new Error('Lua code returned a table and tables are not supported yet');
          break;
        default:
          throw new Error('Lua code returned unsupported data type');
      }
    }

    private function clearStack():void {
    }
  }
}