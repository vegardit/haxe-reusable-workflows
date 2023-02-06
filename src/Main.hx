class Main {

  static function exit(exitCode:Int):Void {
    #if sys
      Sys.stderr().flush();
      Sys.stdout().flush();
      Sys.exit(exitCode);
    #elseif js
      #if (haxe_ver < 4)
        var isPhantomJSDirectExecution = untyped __js__("(typeof phantom !== 'undefined')");
        if(isPhantomJSDirectExecution)
            untyped __js__("phantom.exit(exitCode)");
        else  {
          var isPhantomJSWebPage = untyped __js__("!!(typeof window != 'undefined' && window.callPhantom && window._phantom)");
          if (isPhantomJSWebPage)
            untyped __js__("window.callPhantom({cmd:'doctest:exit', 'exitCode':exitCode})");
          else
            untyped __js__("process.exit(exitCode)"); // nodejs
        }
      #else
        final isPhantomJSDirectExecution = js.Syntax.code("(typeof phantom !== 'undefined')");
        if (isPhantomJSDirectExecution)
          js.Syntax.code("phantom.exit(exitCode)");
        else {
          final isPhantomJSWebPage = js.Syntax.code("!!(typeof window != 'undefined' && window.callPhantom && window._phantom)");
          if (isPhantomJSWebPage)
            js.Syntax.code("window.callPhantom({cmd:'doctest:exit', 'exitCode':exitCode})");
          else
            js.Syntax.code("process.exit(exitCode)"); // nodejs
        }
      #end
    #elseif flash
      // using a delay to give the logger a chance to flush to disk
      haxe.Timer.delay(() -> flash.system.System.exit(exitCode), 2000);
    #end
  }

  #if flash
    @:keep
    static var __static_init = {
      haxe.Log.trace = function(v:Dynamic, ?pos:haxe.PosInfos):Void //
        flash.Lib.trace(pos == null ? '$v' : '${pos.fileName}:${pos.lineNumber}: $v');
    }
  #end

  static public function main():Void {
    trace("Hello World");
    exit(0);
  }
}