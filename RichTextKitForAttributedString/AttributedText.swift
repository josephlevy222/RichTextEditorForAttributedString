//
//  AttributedText.swift
//  RichTextKitForAttributedString
//
//  Created by Joseph Levy on 8/1/24.
//

import SwiftUI

final class TextView: UITextView {
	var maxLayoutWidth: CGFloat = 0 {
		didSet {
			guard maxLayoutWidth != oldValue else { return }
			invalidateIntrinsicContentSize()
		}
	}
	
	override var intrinsicContentSize: CGSize {
		guard maxLayoutWidth > 0 else {
			return super.intrinsicContentSize
		}
		
		return sizeThatFits(
			CGSize(width: maxLayoutWidth, height: .greatestFiniteMagnitude)
		)
	}
}

struct TextViewWrapper: UIViewRepresentable {
	var attributedText: NSAttributedString
	var maxLayoutWidth: CGFloat
	var textViewStore: TextViewStore
	func makeUIView(context: Context) -> TextView {
		let uiView = TextView()
		
		uiView.backgroundColor = .clear
		uiView.textContainerInset = .zero
		uiView.isEditable = true
		uiView.allowsEditingTextAttributes = true
		uiView.isScrollEnabled = false
		uiView.textContainer.lineFragmentPadding = 0
		
		return uiView
	}
	
	func updateUIView(_ uiView: TextView, context: Context) {
		uiView.attributedText = attributedText
		uiView.maxLayoutWidth = maxLayoutWidth
		
		uiView.textContainer.maximumNumberOfLines = context.environment.lineLimit ?? 0
		uiView.textContainer.lineBreakMode = NSLineBreakMode(context.environment.truncationMode)
		
		textViewStore.didUpdateTextView(uiView)
	}
}

extension NSLineBreakMode {
	init(_ truncationMode: Text.TruncationMode) {
		switch truncationMode {
		case .head:
			self = .byTruncatingHead
		case .tail:
			self = .byTruncatingTail
		case .middle:
			self = .byTruncatingMiddle
		@unknown default:
			self = .byWordWrapping
		}
	}
}

final class TextViewStore: ObservableObject {
	@Published private(set) var height: CGFloat?
	
	func didUpdateTextView(_ textView: TextView) {
		height = textView.intrinsicContentSize.height
	}
}

extension GeometryProxy {
	var maxWidth: CGFloat {
		size.width - safeAreaInsets.leading - safeAreaInsets.trailing
	}
}

struct AttributedText: View {
	@StateObject private var textViewStore = TextViewStore()
	private let attributedText: NSAttributedString
	
	init(_ attributedText: NSAttributedString) {
		self.attributedText = attributedText
	}
	
	var body: some View {
		GeometryReader { geometry in
			TextViewWrapper(
				attributedText: attributedText,
				maxLayoutWidth: geometry.maxWidth,
				textViewStore: textViewStore
			)
		}
		.frame(height: textViewStore.height)
	}
}

struct AttributedText_Previews: PreviewProvider {
	static var previews: some View {
		AttributedText(
			NSAttributedString(
				string: "I had called upon my friend, and he was very interested in buying my blue Chevy Nova to my surprise.",
				attributes: [
					.font: UIFont.preferredFont(forTextStyle: .title1),
					.backgroundColor: UIColor.yellow
				]
			)
		).frame(width: 300).fixedSize()
	}
}
