package ;

import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import openfl.Assets;


/**
 * ...
 * @author Mike Almond - https://github.com/mikedotalmond
 */

class Main extends Sprite {
	
	var inited:Bool;

	/* ENTRY POINT */
	
	function resize(e) {
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init() {
		if (inited) return;
		inited = true;
		
		var parser:WOFFParser = new WOFFParser();
		
		// After adding some wOFF sources this should build and work for most of the NME targets (Flash/C/C++),
		// but there are only some traces in there to give feedback... nothing particularly visual
		
		trace("Parsing wOFF: assets/test.woff");
		parser.parse(Assets.getBytes("assets/test.woff"));
		
		trace('woff has ${parser.numTables} font data tables...');
		trace(parser.tables);
	}
	
	
	/* SETUP */
	public function new() {
		super();	
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	function added(e) {
		removeEventListener(Event.ADDED_TO_STAGE, added);
		stage.addEventListener(Event.RESIZE, resize);
		#if ios
		haxe.Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}
	
	public static function main() {
		// static entry point
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}
}