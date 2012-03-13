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


/**
 * ...
 * @author Mike Almond - MadeByPi
 */

package;

import nme.errors.Error;
import nme.utils.ByteArray;
import nme.utils.CompressionAlgorithm;
import nme.utils.Endian;
import nme.Vector;

/**
 * HaXe WOFF (web-open-font-format) parser
 * Converted and updated my earlier AS3 WOFF parser: blog.madebypi.co.uk/2009/11/09/as3-woff-parser/
 *
 * Based on the following WOFF file-format reference http://people.mozilla.org/~jkew/woff/woff-2009-09-16.html
 */
class WOFFParser {
	
	private var woffBytes	:ByteArray;
	public var header		:WOFFHeader;
	public var tables		:Vector<WOFFTable>;
	public var metadata		:WOFFMetadata;
	public var privateData	:ByteArray;
	
	public function new() {
		
	}
	
	public function parse(woffBytes:ByteArray):Void {
		
		if (woffBytes == null) {
			throw new Error("woffBytes was null!");
			return;
		}
		
		this.woffBytes 		= woffBytes;
		woffBytes.endian 	= Endian.BIG_ENDIAN;
		
		// parse WOFF header
		header 	= new WOFFHeader(woffBytes);
		// create a vector to store the tables
		tables 	= new Vector<WOFFTable>();
		
		// Knowing the header information we can parse and build font tables.
		// With the woffBytes.position pointer in the right place after reading the header
		// we continue thorough the file and parse the tables from the TableDirectoryEntry block
		var i:Int	= -1;
		var n:Int 	= header.numTables;
		while (++i < n) tables.push(new WOFFTable(woffBytes));
		
		//next, extract and parse any metadata xml
		metadata = new WOFFMetadata(woffBytes, header.metaOffset, header.metaLength);
		
		// if there's private data, extract it and store it...
		if (header.privateLength > 0 && cast(woffBytes.length, Int) == (header.privateOffset + header.privateLength)) {
			privateData = new ByteArray();
			privateData.writeBytes(woffBytes, header.privateOffset, header.privateLength);
		}
		
		if (header.valid) {
			trace("[WOFFParser] Parsed WOFF data...");
			trace(header);
			trace(metadata);
		} else {
			trace("[WOFFParser] There was a problem parsing the WOFF data :(");
		}
	}
	
	public function isValid():Bool { return header != null && header.valid; }
	public function hasMetadata():Bool { return metadata.data != null; }
	public function hasPrivateData():Bool { return privateData != null; }
	
	public function numTables():Int { return tables.length; }
	public function getTableAt(index:Int):WOFFTable { return tables[index]; }
}


/**
 *
 */
class WOFFHeader {
	/*
	WOFFHeader
	UInt32	signature	0x774F4646 'wOFF'
	UInt32	flavor	The "sfnt version" of the original file: 0x00010000 for TrueType flavored fonts or 0x4F54544F 'OTTO' for CFF flavored fonts.
	UInt32	length	Total size of the WOFF file.
	UInt16	numTables	Number of entries in directory of font tables.
	UInt16	reserved	Reserved, must be set to zero.
	UInt32	totalSfntSize	Total size needed for the uncompressed font data, including the sfnt header, directory, and tables.
	UInt16	majorVersion	Major version of the WOFF font, not necessarily the major version of the original sfnt font.
	UInt16	minorVersion	Minor version of the WOFF font, not necessarily the minor version of the original sfnt font.
	UInt32	metaOffset	Offset to metadata block, from beginning of WOFF file; zero if no metadata block is present.
	UInt32	metaLength	Length of compressed metadata block; zero if no metadata block is present.
	UInt32	metaOrigLength	Uncompressed size of metadata block; zero if no metadata block is present.
	UInt32	privOffset	Offset to private data block, from beginning of WOFF file; zero if no private data block is present.
	UInt32	privLength	Length of private data block; zero if no private data block is present.
	*/

	private static var SFNT_VERSION_TTF	:Int = 0x00010000;
	private static var SFNT_VERSION_CFF	:Int = 0x4F54544F;
	
	public var valid			:Bool;
	
	// Header values
	public var sfntVersion		:Int;
	public var woffLength		:Int;
	public var numTables		:Int;
	public var totalSfntSize	:Int;
	public var majorVersion		:Int;
	public var minorVersion		:Int;
	public var metaOffset		:Int;
	public var metaLength		:Int;
	public var metaOrigLength	:Int;
	public var privateOffset	:Int;
	public var privateLength	:Int;
	
	public function new(bytes:ByteArray) {
		
		valid = false;
		
		// check signature
		if ( bytes.readUTFBytes(4) != "wOFF") {
			throw new Error("Not a valid WOFF file, invalid signature");
			return;
		}
		
		sfntVersion 	= bytes.readUnsignedInt();
		woffLength 		= bytes.readUnsignedInt();
		numTables 		= bytes.readShort();
		
		// check version
		if (sfntVersion != SFNT_VERSION_TTF && sfntVersion != SFNT_VERSION_CFF) {
			throw new Error("Not a valid WOFF file, invalid sfntVersion");
			return;
		}
		
		// check reserved
		if (bytes.readShort() != 0) {
			throw new Error("Not a valid WOFF file, reserved data was not zero");
			return;
		}
		
		totalSfntSize 	= bytes.readUnsignedInt();
		majorVersion 	= bytes.readShort();
		minorVersion 	= bytes.readShort();
		metaOffset 		= bytes.readUnsignedInt();
		metaLength 		= bytes.readUnsignedInt();
		metaOrigLength 	= bytes.readUnsignedInt();
		privateOffset 	= bytes.readUnsignedInt();
		privateLength 	= bytes.readUnsignedInt();
		valid 			= true;
	}
	
	
	public function sfntVersionString():String {
		return sfntVersion == SFNT_VERSION_CFF ? "cff" : "ttf";
	}
	
	public function toString():String {
		return valid ? (
			"[WOFFHeader] " 	+
			"sfntVersion:" 		+ sfntVersion + " (" + sfntVersionString() + "), " +
			"woffLength:" 		+ woffLength + ", " +
			"numTables:" 		+ numTables + ", " +
			"totalSfntSize:" 	+ totalSfntSize + ", " +
			"majorVersion:" 	+ majorVersion + ", " +
			"minorVersion:" 	+ minorVersion + ", " +
			"metaOffset:" 		+ metaOffset + ", " +
			"metaLength:" 		+ metaLength + ", " +
			"metaOrigLength:" 	+ metaOrigLength + ", " +
			"privOffset:" 		+ privateOffset + ", " +
			"privateLength:" 	+ privateLength)
			
			: "[WOFFHeader] [ERROR] Not a valid WOFF file :(";
	}
}


/**
 *
 */
class WOFFTable {
	
	/*
	WOFF TableDirectoryEntry
	UInt32	tag	4-byte sfnt table identifier.
	UInt32	offset	Offset to the data, from beginning of WOFF file.
	UInt32	compLength	Length of the compressed data, excluding padding.
	UInt32	origLength	Length of the uncompressed table, excluding padding.
	UInt32	origChecksum	Checksum of the uncompressed table.
	
	// apparently sfnt stands for spline font...
	// https://developer.apple.com/fonts/tools/tooldir/TrueEdit/Documentation/TE/TE1sfnt.html
	// TODO: parse this sfnt data.... Would be good to get something useful out at the end really... AdobeFontMetrics or a TTF/OTF...
	*/
	
	// header values
	public var tag					:String;
	public var offset				:Int;
	public var compLength			:Int;
	public var origLength			:Int;
	public var origChecksum			:Int;
	
	// sfnt-based font table data (ttf or cff)
	private var _data				:ByteArray;
	
	public function new(bytes:ByteArray) {
		// read the current header
		
		tag 			= bytes.readUTFBytes(4);
		offset 			= bytes.readUnsignedInt();
		compLength 		= bytes.readUnsignedInt();
		origLength 		= bytes.readUnsignedInt();
		origChecksum 	= bytes.readUnsignedInt();
		
		// copy the font table bytes
		_data = new ByteArray();
		_data.writeBytes(bytes, offset, compLength);
		_data.position = 0;
		
		// if compressed, uncompress
		if (compressed) _data.uncompress(); // ByteArray uncompress not available in JS...
		
		if (cast(_data.length, Int) != origLength) { // Flash target needs a cast here
			// TODO: Calcualte + Validate the checksum (is it just a CRC?) of the decompressed data against the embedded .origChecksum value
			throw new Error("Uncompressed size does not match the original size, table data is probably corrupt");
		}
	}
	
	// get compressed
	public var compressed(getIsCompressed, never):Bool;
	private function getIsCompressed():Bool { return origLength != compLength; }
	
	// get data
	public var data(getData, never)	:ByteArray;
	private function getData()		:ByteArray { return _data; }
	
	
	public function toString():String {
		return "[WOFFTable] tag:" + tag + ", compLength:" + compLength + ", origLength:" + origLength;
	}
}


/**
 *
 */
class WOFFMetadata {
	
	public var data				:Xml;
	
	public var metadataVersion	:String;
	public var uniqueid			:String;
	public var vendorName		:String;
	public var licenseeName		:String;
	public var licenceId		:String;
	public var licenceUrl		:String;
	
	public var licenseText		:Vector<Xml>;
	public var copyrightText	:Vector<Xml>;
	public var descriptionText	:Vector<Xml>;
	public var trademarkText	:Vector<Xml>;
	public var credits			:Vector<WOFFCredit>;
	
	public function new(bytes:ByteArray, offset:Int, length:Int) {
		
		if (length == 0 || (length > 0 && cast(bytes.length, Int) <= offset + length)) return;
		
		var b:ByteArray = new ByteArray();
		b.writeBytes(bytes, offset, length);
		b.uncompress();
		
		try {
			data = Xml.parse(b.readUTFBytes(b.length)).firstElement();
		} catch (err:Error) {
			trace("Error parsing WOFF meta xml");
			trace(err);
			return;
		}
		
		metadataVersion = data.get("version");
		
		var creditNodes:Iterator<Xml> = null;
		
		for ( elt in data.elements() ) {
			
			//trace("nodeName: " + elt.nodeName);
			
			switch(elt.nodeName) {
				case "uniqueid"		: uniqueid 			= elt.get("id");
				case "vendor"		: vendorName 		= elt.get("name");
				case "licensee"		: licenseeName		= elt.get("name");
				case "credits"		: creditNodes		= elt.elementsNamed("credit");
				case "description"	: descriptionText	= nodeIteratorToArray(elt.elementsNamed("text"));
				case "copyright"	: copyrightText		= nodeIteratorToArray(elt.elementsNamed("text"));
				case "trademark"	: trademarkText		= nodeIteratorToArray(elt.elementsNamed("text"));
				
				case "license"		:
					licenceId		= elt.get("id");
					licenceUrl		= elt.get("url");
					licenseText		= nodeIteratorToArray(elt.elementsNamed("text"));
					
				default				: trace("Unhandled node: " + elt.nodeName);
			}
		}
		
		if (creditNodes != null) {
			credits = new Vector<WOFFCredit>();
			while (creditNodes.hasNext()) credits.push(new WOFFCredit(creditNodes.next()));
		}
	}
	
	private function nodeIteratorToArray(nodes:Iterator<Xml>):Vector<Xml> {
		if (!nodes.hasNext()) return null;
		
		var out:Vector<Xml> = new Vector<Xml>();
		for (node in nodes) out.push(node);
		return out;
	}
	
	
	public function toString():String {
		return (data != null) ? (
			"[WOFFMetadata]\n" 				+
			"\tmetadataVersion: " 			+ metadataVersion + ", \n" +
			"\tuniqueid: " 					+ uniqueid + ", \n" +
			"\tvendorName: " 				+ vendorName + ", \n" +
			"\tdescription languages: ["	+ availableLanguages(descriptionText) + "], \n" +
			"\tlicense languages: [" 		+ availableLanguages(licenseText) + "], \n" +
			"\tcopyright languages: [" 		+ availableLanguages(copyrightText) + "], \n" +
			"\tcredits: " 					+ credits)
			
			: "[WOFFMetadata] No WOFF Metadata present";
	}
	
	public function getDescriptionText(languageCode:String = "en"):String {
		return descriptionText == null ? null : getTextForLanguage(descriptionText, languageCode);
	}
	
	public function getLicenceText(languageCode:String = "en"):String {
		return licenseText==null ? null : getTextForLanguage(licenseText, languageCode);
	}
	
	public function getCopyrightText(languageCode:String = "en"):String {
		return copyrightText == null ? null : getTextForLanguage(copyrightText, languageCode);
	}
	
	public function availableLanguages(nodes:Vector<Xml>):Vector<String> {
		if (null==nodes) return null;
		
		var out = new Vector<String>();
		for (node in nodes) out.push(node.get("lang"));
		return out;
	}
	
	private function getTextForLanguage(nodes:Vector<Xml>, languageCode:String):String {
		for (node in nodes) {
			if (node.get("lang") == languageCode) return node.firstChild().toString();
		}
		return null;
	}
 }


 /**
  *
  */
 class WOFFCredit {
	
	public var name	:String;
	public var role	:String;
	public var url	:String;
	
	public function new(data:Xml) {
		name	= data.get("name");
		role	= data.get("role");
		url		= data.get("url");
	}
	
	public function toString():String {
		return 	"[WOFFCredit]" +
				" name: " + name +
				", role: " + role +
				", url: " + url;
	}
 }