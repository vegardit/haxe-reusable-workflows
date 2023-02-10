class MainWithError extends Main {

  static public function main():Void {
    trace("Hello World");
    Main.exit(1);
  }
}