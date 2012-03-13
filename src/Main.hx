/*
Copyright (c) 2012 Mike.Almond, MadeByPi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

package ;

import nme.Assets;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.errors.Error;
import nme.Lib;

/**
 * ...
 * @author Mike Almond - MadeByPi
 */

class Main {
	
	static public function main() {
		
		var stage 		= Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align 	= StageAlign.TOP_LEFT;
		// entry point
		
		var parser:WOFFParser = new WOFFParser();
		
		// After adding some wOFF sources this should build and work for most of the NME targets (Flash/C/C++),
		// but there are only some traces in there to give feedback... nothing particularly visual
		
		try {
			parser.parse(Assets.getBytes("assets/this-does-not-exist.woff"));
		} catch (e:Error) {
			trace(e);
		}
		
		trace("Parsing wOFF: assets/YOUR_WOFF_FILE_HERE.woff");
		parser.parse(Assets.getBytes("assets/YOUR_WOFF_FILE_HERE.woff"));
		
		trace("----------------------------------------------------------------------");
		
		trace("Parsing wOFF: assets/ANOTHER_WOFF_FILENAME.woff");
		parser.parse(Assets.getBytes("assets/ANOTHER_WOFF_FILENAME.woff"));
	}
}