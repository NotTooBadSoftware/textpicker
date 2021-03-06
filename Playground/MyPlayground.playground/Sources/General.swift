//
//  General.swift
//  PlaygroundView
//
//  Created by Kåre Morstøl on 13/06/2020.
//

import AppKit
import Patterns

typealias Attributes = [NSAttributedString.Key: Any]

let defaultTextAttributes: Attributes = {
	let defaultTextSize = CGFloat(14)
	let font = NSFont(name: "Menlo", size: defaultTextSize)
		?? NSFont.monospacedDigitSystemFont(ofSize: defaultTextSize, weight: .regular)
	return [.font: font, .foregroundColor: NSColor.textColor, .backgroundColor: NSColor.textBackgroundColor]
}()

let defaultCapturedAttributes =
	[NSColor.systemGreen, .systemPurple, .systemOrange, .systemTeal, .systemBlue, .systemRed]
	.map { color -> Attributes in
		var attribs = defaultTextAttributes
		attribs[.backgroundColor] = color.withAlphaComponent(0.5)
		return attribs
	}

func adorn<S: Sequence>(_ string: String, matches: S) -> (NSMutableAttributedString, [String: Attributes])
	where S.Element == Parser<String>.Match {
	var capturedAttributes = defaultCapturedAttributes.repeatForever().makeIterator()
	let attributedString = NSMutableAttributedString(string: string, attributes: defaultTextAttributes)
	var captureColors = [String: Attributes]()
	for match in matches {
		for (name, range) in match.captures {
			let nsrange = NSRange(range, in: string)
			if captureColors[name ?? "unnamed"] == nil { captureColors[name ?? "unnamed"] = capturedAttributes.next()! }
			let attributes = captureColors[name ?? "unnamed"]
			attributedString.setAttributes(attributes, range: nsrange)
		}
	}

	return (attributedString, captureColors)
}

extension Sequence {
	func repeatForever() -> LazySequence<UnfoldSequence<Element, Iterator>> {
		sequence(state: self.makeIterator()) { (iterator: inout Iterator) -> Element? in
			iterator.next() ?? {
				iterator = self.makeIterator()
				return iterator.next()
			}()
		}.lazy
	}
}

extension NSAttributedString {
	var nsRange: NSRange { NSRange(location: 0, length: self.length) }
}

import AppKit
import SwiftUI

struct Label: NSViewRepresentable {
	typealias TheUIView = NSTextView
	var configuration = { (view: TheUIView) in }

	func makeNSView(context: Context) -> TheUIView {
		let view = TheUIView()
		view.isEditable = false
		return view
	}

	func updateNSView(_ nsView: TheUIView, context: Context) {
		configuration(nsView)
	}
}

struct SingleLineLabel: NSViewRepresentable {
	typealias TheUIView = NSTextField
	let content: NSAttributedString

	func makeNSView(context: Context) -> TheUIView {
		let view = TheUIView(labelWithAttributedString: content)
		view.isEditable = false
		//view.alignment = .center
		return view
	}

	func updateNSView(_ nsView: TheUIView, context: Context) {}
}

import PlaygroundSupport

public func showParserView<P: Patterns.Pattern>(ofSize size: NSSize = NSSize(width: 600, height: 600), pattern: P, withText text: String) throws {
	let view = try ParserView(text: text, pattern: pattern)
	let hosting = NSHostingController(rootView: view)
	hosting.view.frame.size = size
	PlaygroundPage.current.setLiveView(hosting)
}
