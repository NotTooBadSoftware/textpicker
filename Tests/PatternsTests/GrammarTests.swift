//
//  GrammarTests.swift
//
//
//  Created by Kåre Morstøl on 27/05/2020.
//

@testable import Patterns
import XCTest

class GrammarTests: XCTestCase {
	let grammar1: Grammar<String> = {
		let g = Grammar()
		g.letter <- Capture(letter)
		g.space <- whitespace
		return g
	}()

	func testNamesAnonymousCaptures() {
		XCTAssertEqual((grammar1.patterns.first?.pattern.wrapped as? Capture<OneOf<String>>)?.name, "letter")
	}

	func testSetsFirstPattern() {
		XCTAssertEqual(grammar1.firstPattern, "letter")
	}

	func testDirectRecursion1() throws {
		let g = Grammar()
		g.a <- "a" / any • g.a
		let parser = try Parser(g)
		assertParseAll(parser, input: " aba", count: 2)
	}

	func testDirectRecursion2() throws {
		let g = Grammar()
		g.balancedParentheses <- "(" • (!OneOf("()") • any / g.balancedParentheses)* • ")"
		let parser = try Parser(g)
		assertParseAll(parser, input: "( )", count: 1)
		assertParseAll(parser, input: "((( )( )))", count: 1)
		assertParseAll(parser, input: "(( )", count: 0)
	}

	func testArithmetic() throws {
		let g = Grammar { g in
			g.all <- g.expr • !any
			g.expr <- g.sum
			g.sum <- g.product • (("+" / "-") • g.product)*
			g.product <- g.power • (("*" / "/") • g.power)*
			g.power <- g.value • ("^" • g.power)¿
			g.value <- digit+ / "(" • g.expr • ")"
		}

		let p = try Parser(g)
		assertParseMarkers(p, input: "1+2-3*(4+3)|")
		assertParseAll(p, input: "1+2(", count: 0)
	}

	func testOptimisesTailCall() throws {
		let g = Grammar<String.UTF8View> { g in
			g.a <- " " / Skip() • g.a
		}

		func isCall(_ inst: Instruction<String.UTF8View>) -> Bool {
			switch inst {
			case .call: return true
			default: return false
			}
		}

		XCTAssertEqual(try Parser(g).matcher.instructions.filter(isCall(_:)).count, 1)
		XCTAssertEqual(try Parser(search: g).matcher.instructions.filter(isCall(_:)).count, 1)
	}
}
