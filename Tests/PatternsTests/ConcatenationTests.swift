//
//  ConcatenationTests
//
//  Created by Kåre Morstøl on 18/05/2018.
//

import Patterns
import XCTest

class ConcatenationTests: XCTestCase {
	func testSimple() throws {
		assertParseAll(
			Capture(Literal("a")¿ • "b"),
			input: "ibiiiiabiii", result: ["b", "ab"])
		assertParseAll(
			Capture(Literal("a")¿ • Literal("b")),
			input: "ibiiaiiababiibi", result: ["b", "ab", "ab", "b"])
		assertParseAll(
			Capture("b" • Literal("a")¿),
			input: "ibiiiibaiii", result: ["b", "ba"])

		let p = Capture("ab" • digit • ".")
		assertParseAll(p, input: "$#%/ab8.lsgj", result: "ab8.", count: 1)
		assertParseAll(p, input: "$ab#%/ab8.lsgab3.j", result: ["ab8.", "ab3."])
		assertParseAll(p, input: "$#%/ab8lsgj", count: 0)
	}

	func testRepeat() throws {
		let text = "This is 4 6 a test 123 text."
		assertParseAll(
			Capture(" " • digit* • " "),
			input: text, result: [" 4 ", " 123 "])
		assertParseAll(
			" " • Capture(digit*) • " ",
			input: text, result: ["4", "6", "123"])
		assertParseAll(
			Capture(digit • letter.repeat(0 ... 2)),
			input: "2a 35abz2",
			result: ["2a", "3", "5ab", "2"])
	}

	func testCapture() throws {
		assertParseAll(
			Capture() • "a",
			input: "xaa xa", result: "", count: 3)
		assertParseAll(
			"x" • Capture() • "a",
			input: "xaxa xa", result: "", count: 3)
		assertParseAll(
			Capture() • "a",
			input: "xaa xa".utf8, result: "".utf8, count: 3)
		assertParseAll(
			"x" • Capture() • "a",
			input: "xaxa xa".unicodeScalars, result: "".unicodeScalars, count: 3)

		let text = "This is a test text."
		assertParseAll(
			" " • Capture(letter+) • " ",
			input: text, result: ["is", "a", "test"])
		assertParseAll(
			Capture(letter+),
			input: text, result: ["This", "is", "a", "test", "text"])
		assertParseAll(
			letter • Capture() • " ",
			input: text, result: "", count: 4)
		assertParseAll(
			" " • Capture("te"),
			input: text, result: "te", count: 2)

		XCTAssert(type(of: Capture()).Input == String.self)
		XCTAssert(type(of: "q" • Capture()).Input == String.self)
		XCTAssert(type(of: Literal("q".utf8) • Capture()).Input == String.UTF8View.self)
	}

	func testRepeatOrThenEndOfLine() throws {
		assertParseAll(
			Capture((alphanumeric / OneOf(" "))+ • Line.End()),
			input: "FMA026712 TECNOAUTOMOTRIZ ATLACOMULCO S",
			result: ["FMA026712 TECNOAUTOMOTRIZ ATLACOMULCO S"])
	}

	func testMatchFullRange() throws {
		let text = """
		line 1

		line 3
		line 4

		"""

		assertParseAll(Capture(Line()), input: text,
		               result: ["line 1", "", "line 3", "line 4", ""])
	}

	func testMatchBeginningOfLines() throws {
		let text = """
		airs
		blip
		cera user
		dilled10 io
		"""
		let pattern = try Parser(search: Line.Start() • Capture())

		let m = Array(pattern.matches(in: text))
		XCTAssertEqual(m.map { text[$0.captures[0].range.lowerBound] }, ["a", "b", "c", "d"].map(Character.init))

		XCTAssertEqual(pattern.matches(in: "\n\n").map { $0.captures[0] }.count, 3)
	}

	func testMatchEndOfLines() throws {
		let text = """
		airs
		blip
		cera user
		dilled10 io

		"""

		var pattern = try Parser(search: Line.End() • Capture())
		var m = pattern.matches(in: text)
		XCTAssertEqual(m.dropLast().map { text[$0.captures[0].range.lowerBound] },
		               Array(repeating: Character("\n"), count: 4))

		pattern = try Parser(search: Capture() • Line.End())
		m = pattern.matches(in: text)
		XCTAssertEqual(m.dropLast().map { text[$0.captures[0].range.lowerBound] },
		               Array(repeating: Character("\n"), count: 4))
	}

	func testMultipleCaptures() throws {
		let text = """
		There was a young woman named Bright,
		Whose speed was much faster than light.
		She set out one day,
		In a relative way,
		And returned on the previous night.
		"""

		let twoFirstWords = [["There", "was"], ["Whose", "speed"], ["She", "set"], ["In", "a"], ["And", "returned"]]
		let pattern =
			Line.Start() • Capture(name: "word", letter+)
			• " " • Capture(name: "word", letter+)

		assertCaptures(pattern, input: text, result: twoFirstWords)

		let matches = Array(try Parser(search: pattern).matches(in: text))
		XCTAssertEqual(matches.map { text[$0[one: "word"]!] }, ["There", "Whose", "She", "In", "And"])
		XCTAssertEqual(matches.map { $0[multiple: "word"].map { String(text[$0]) } }, twoFirstWords)
		XCTAssertNil(matches.first![one: "not a name"])
	}

	let text = """
	# ================================================

	0005..0010    ; Common # Cc  [32] <control-0000>..<control-001F>
	002F          ; Common # Zs       SPACE
	"""

	lazy var rangeAndProperty: Parser<String> = {
		let hexNumber = Capture(name: "codePoint", hexDigit+)
		let hexRange = AnyPattern("\(hexNumber)..\(hexNumber)") / hexNumber
		return try! Parser(search: AnyPattern("\n\(hexRange • Skip()); \(Capture(name: "property", Skip())) "))
	}()

	func testStringInterpolation() throws {
		assertCaptures(rangeAndProperty, input: text, result: [["0005", "0010", "Common"], ["002F", "Common"]])
	}

	func testAnyPattern() throws {
		let text = """
		 : Test Case '-[PerformanceTests.PerformanceTests testAnyNumeral]' measured [CPU Instructions Retired, kI] average: 6071231.970, relative standard deviation: 0.300%, values: [6125777.558000, 6066280.613000, 6064787.491000, 6063915.538000, 6066853.091000, 6063079.064000, 6068140.744000, 6064901.279000, 6064321.893000, 6064262.431000], performanceMetricID:com.apple.dt.XCTMetric_CPU.instructions_retired, baselineName: "", baselineAverage: , maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000

		"""
		let skip = Skip()
		let measurementPattern = AnyPattern("""
		: Test Case '-[\(skip).\(Capture(name: "name", skip))]' measured [\(Capture(name: "measurementName", skip)), \(Capture(name: "measurementUnit", skip))] average: \(Capture(name: "average", skip)), relative standard deviation: \(Capture(name: "standardDeviation", skip))%\(skip), performanceMetricID:\(Capture(name: "measurementID", skip)),\(skip)

		""")
		assertParseAll(measurementPattern, input: text, count: 1)
	}

	func testMatchDecoding() throws {
		struct Property: Decodable, Equatable {
			let codePoint: [Int]
			let property: String
			let notCaptured: String?
		}

		let matches = Array(rangeAndProperty.matches(in: text))
		let property = try matches.first!.decode(Property.self, from: text)
		XCTAssertEqual(property, Property(codePoint: [5, 10], property: "Common", notCaptured: nil))

		XCTAssertThrowsError(try matches.last!.decode(Property.self, from: text))
	}

	func testParserDecoding() {
		struct Property: Decodable, Equatable {
			let codePoint: [String]
			let property: String
		}

		XCTAssertEqual(try rangeAndProperty.decode([Property].self, from: text),
		               [Property(codePoint: ["0005", "0010"], property: "Common"),
		                Property(codePoint: ["002F"], property: "Common")])
		XCTAssertEqual(try rangeAndProperty.decodeFirst(Property.self, from: text),
		               Property(codePoint: ["0005", "0010"], property: "Common"))
	}
}
