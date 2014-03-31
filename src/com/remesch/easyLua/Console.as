// This file is based on luatest.mxml from Adobe CrossBridge's Example_Lua directory.

package com.remesch.easyLua
{
  import sample.lua.CModule;
  import sample.lua.vfs.ISpecialFile;

  public class Console implements sample.lua.vfs.ISpecialFile
  {
    public function Console() {
    }

    //
    // Public methods.
    //

    public function write(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int {
      var result:String = CModule.readString(bufPtr, nbyte);
      trace(result);

      return nbyte;
    }

    public function read(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int {
      return 0;
    }

    public function fcntl(fd:int, com:int, data:int, errnoPtr:int):int {
      return 0;
    }

    public function ioctl(fd:int, com:int, data:int, errnoPtr:int):int {
      return 0;
    }
  }
}