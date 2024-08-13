//
//  RichTextEditor.swift
//  RichTextKitForAttributedString
//
//  Created by Joseph Levy on 7/29/24.
//
import SwiftUI

struct RichTextEditor: UIViewRepresentable {
	@Binding var attributedText: AttributedString
	
	@State private var toolbar = KeyboardToolbar(textView: RichTextView())
	var textView: RichTextView { toolbar.textView } // created with toolbar above
	
	func makeUIView(context: Context) -> UITextView {
		textView.accessoryView = KeyboardAccessoryView(toolbar: $toolbar)
		textView.attributedText = attributedText.nsAttributedString()
		textView.textContainerInset = UIEdgeInsets.zero
		textView.textContainer.lineFragmentPadding = 0
		textView.allowsEditingTextAttributes = true
		textView.delegate = context.coordinator
		textView.isEditable = true
		
		let accessoryViewController = UIHostingController(rootView: textView.accessoryView)
		textView.inputAccessoryView = {
			let accessoryView = accessoryViewController.view
			if let accessoryView {
				let frameSize = CGRect(x: 0, y: 0, width: 100, height: 44)
				accessoryView.frame = frameSize }
			return accessoryView
		}()
		return textView
	}
	
	func updateUIView(_ uiView: UITextView, context: Context) {
		uiView.attributedText = attributedText.nsAttributedString()
		print("update UITextView")
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, UITextViewDelegate {
		var parent: RichTextEditor
		init(_ parent: RichTextEditor) {
			self.parent = parent
		}
		
		func textViewDidChange(_ textView: UITextView) {
			parent.attributedText =  textView.attributedText.attributedStringFromUIKit
			textViewDidChangeSelection(textView)
			print("text did change")
		}
	}
}

class RichTextView: UITextView, ObservableObject {
	public var accessoryView: KeyboardAccessoryView?
	var toolbar: Binding<KeyboardToolbar>? { accessoryView?.$toolbar }
}


















//extension RichTextView {
//	//var selectedRange: NSRange { textView.selectedRange }
//	func toggleBoldface() {
//		toggleSymbolicTrait(.traitBold)
//	}
//	
//	func toggleItalics() {
//		toggleSymbolicTrait(.traitItalic)
//	}
//	
//	private func toggleSymbolicTrait(_ trait: UIFontDescriptor.SymbolicTraits)  {
//		//inputClick.play()
//		if selectedRange.isEmpty { // toggle typingAttributes
//			toolbar?.justChanged = true
//			let uiFont = toolbar?.textView.typingAttributes[.font] as? UIFont
//			if let descriptor = uiFont?.fontDescriptor {
//				let isBold = descriptor.symbolicTraits.intersection(.traitBold) == .traitBold
//				let isTrait = descriptor.symbolicTraits.intersection(trait) == trait
//				// Fix bug in largeTitle by setting bold weight directly
//				var weight = isBold ? .bold : descriptor.weight
//				weight = trait != .traitBold ? weight : (isBold ? .regular : .bold)
//				if let fontDescriptor = isTrait ? descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
//					: descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait)) {
//					toolbar?.textView.typingAttributes[.font] = UIFont(descriptor: fontDescriptor.withWeight(weight), size: descriptor.pointSize)
//				}
//				if let didChangeSelection = toolbar?.textView.delegate?.textViewDidChangeSelection { didChangeSelection(toolbar!.textView) }
//			}
//			
//		} else {
//			let attributedString = NSMutableAttributedString(attributedString: attributedText)
//			var isAll = true
//			attributedString.enumerateAttribute(.font, in: selectedRange,
//												options: []) { (value, range, stopFlag) in
//				let uiFont = value as? UIFont
//				if let descriptor = uiFont?.fontDescriptor {
//					let isTrait = (descriptor.symbolicTraits.intersection(trait) == trait)
//					isAll = isAll && isTrait
//					if !isAll { stopFlag.pointee = true }
//				}
//			}
//			attributedString.enumerateAttribute(.font, in: selectedRange,
//												options: []) {(value, range, stopFlag) in
//				let uiFont = value as? UIFont
//				if  let descriptor = uiFont?.fontDescriptor {
//					// Fix bug in largeTitle by setting bold weight directly
//					var weight = descriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : descriptor.weight
//					weight = trait != .traitBold ? weight : (isAll ? .regular : .bold)
//					if let fontDescriptor = isAll ? descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
//						: descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait)) {
//						attributedString.addAttribute(.font, value: UIFont(descriptor: fontDescriptor.withWeight(weight),
//																		   size: descriptor.pointSize), range: range)
//					}
//				}
//			}
//			updateAttributedText(with: attributedString)
//		}
//		
//		func updateAttributedText(with attributedText: NSAttributedString) {
//			let selection = toolbar?.textView.selectedRange
//			toolbar?.textView.updateAttributedText(with: attributedText)
//			toolbar?.textView.selectedRange = selection!
//		}
//	}
//}

//		var selectedAttributes: [NSAttributedString.Key : Any] {
//			let textRange = parent.textView.selectedRange
//			var textAttributes = parent.textView.typingAttributes
//			if textRange.length != 0 {
//				//textAttributes = [:] // Uncomment to avoid system putting values in typingAttributes
//				parent.textView.attributedText.enumerateAttributes(in: textRange) { attributes, range, stop in
//					for item in attributes {
//						textAttributes[item.key] = item.value
//					}
//				}
//			}
//			return textAttributes
//		}
//
//		var selectedRangeAttributes: [(NSRange, [NSAttributedString.Key : Any])] {
//			let textRange = parent.textView.selectedRange
//			if textRange.length == 0 { return [(textRange, parent.textView.typingAttributes)]}
//			var textAttributes: [(NSRange, [NSAttributedString.Key : Any])] = []
//			parent.textView.attributedText.enumerateAttributes(in: textRange) { attributes, range, stop in
//				textAttributes.append((range,attributes))
//			}
//			return textAttributes
//		}
//
//		func textViewDidChangeSelection(_ textView: UITextView) {
//			let attributes = selectedAttributes
//			var updateFunc = {}
//			//let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
//			let fontTraits: (isBold: Bool,isItalic: Bool,fontSize: CGFloat, offset: CGFloat) = {
//				let offset = attributes[.baselineOffset] as? CGFloat ?? 0.0
//				let pointSize: CGFloat
//				let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits
//				let bold = traits?.intersection(.traitBold).contains(.traitBold) ?? false
//				let italic = traits?.intersection(.traitItalic).contains(.traitItalic) ?? false
//
//				if parent.toolbar.justChanged {
//					pointSize = parent.toolbar.fontSize
//					return ( bold, italic, pointSize, offset)
//				} else {
//					if let font=attributes[.font] as? UIFont {
//						pointSize = font.pointSize / (offset == 0.0 ? 1.0 : 0.75)
//						// pointSize is the fontSize that the toolbar ought to use unless justChanged
//						return (font.contains(trait: .traitBold),font.contains(trait: .traitItalic), pointSize, offset)
//					}
//					//print("Non UIFont may be Font in \(parent.textView.attributedText), try to convert...")
//
//					// Try to convert Font to UIFont
//					if let font = attributes[.font] as? Font { // { was ,
//						let uiFont = //UIFont(font: font, traitCollection: .current)
//						font.uiFont() ?? UIFont.preferredFont(forTextStyle: .body)
//						pointSize = uiFont.pointSize / (offset == 0.0 ? 1.0 : 0.75)
//						// pointSize is the fontSize that the toolbar ought to use unless justChanged
//						return (uiFont.contains(trait: .traitBold),uiFont.contains(trait: .traitItalic), pointSize, offset)
//					}
//					pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
//					print("Non UIFont in fontTraits default pointSize is \(pointSize)")
//
//					// Fix font
//					let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
//					var font: UIFont
//					let defaultFont = UIFont.preferredFont(forTextStyle: .body)
//					//let selection = textView.selectedRange
//					//textView.selectedRange = NSRange(location: 0,length: textView.attributedText.length)
//					let rangesAttributes = selectedRangeAttributes
//					for (range, attributes) in rangesAttributes {
//						font = attributes[.font] as? UIFont ?? defaultFont
//						let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold
//						? .bold : font.fontDescriptor.weight
//						let size = font.fontDescriptor.pointSize
//						font = UIFont(descriptor: font.fontDescriptor, size: size).withWeight(weight)
//						mutableString.removeAttribute(.font, range: range)
//						mutableString.addAttributes([.font : font], range: range)
//					}
//					updateFunc = {(textView as? RichTextView)?.updateAttributedText(with: mutableString)}
//				}
//				return ( false, false, pointSize, offset)
//			}()
//
//			var isUnderline: Bool {
//				parent.toolbar.justChanged ? parent.toolbar.isUnderline : {
//					if let style = attributes[.underlineStyle] as? Int {
//						return style == NSUnderlineStyle.single.rawValue // or true
//					} else {
//						return false
//					}
//				}()
//			}
//
//			var isStrikethrough: Bool {
//				parent.toolbar.justChanged ? parent.toolbar.isStrikethrough : {
//					if let style = attributes[.strikethroughStyle] as? Int {
//						return style == NSUnderlineStyle.single.rawValue
//					} else {
//						return false
//					}
//				}()
//			}
//
//			var isScript: (sub: Bool,super: Bool) {
//				return parent.toolbar.justChanged
//				? (parent.toolbar.isSubscript, parent.toolbar.isSuperscript)
//				: (fontTraits.offset < 0.0, fontTraits.offset > 0.0)
//			}
//
//			var color: UIColor { selectedAttributes[.foregroundColor] as? UIColor ?? UIColor.label }
//			var background: UIColor  { selectedAttributes[.backgroundColor] as? UIColor ?? UIColor.systemBackground }
//
//			if let color = parent.textView.typingAttributes[.backgroundColor] as? UIColor, color.luminance < 0.55 {
//				textView.tintColor =  .cyan
//			} else {
//				textView.tintColor = .tintColor
//			}
//			DispatchQueue.main.async { [self] in
//				parent.toolbar.fontSize = fontTraits.fontSize
//				parent.toolbar.isBold = fontTraits.isBold
//				parent.toolbar.isItalic = fontTraits.isItalic
//				parent.toolbar.isUnderline = isUnderline
//				parent.toolbar.isStrikethrough = isStrikethrough
//				let script = isScript
//				parent.toolbar.isSuperscript = script.1 //isSuperscript
//				parent.toolbar.isSubscript = script.0 //isSubscript
//				parent.toolbar.color = Color(uiColor: color)
//				parent.toolbar.background = Color(uiColor: background)
//				parent.toolbar.justChanged = false
//				parent.toolbar.textAlignment = textView.textAlignment
//				//(textView as? RichTextView)?.updateAttributedText(with: mutableString)
//				updateFunc()
//			}
//		}
//
//		func textViewDidBeginEditing(_ textView: UITextView) {
//
////			if textView.attributedText.string == parent.placeholder {
////				textView.attributedText = NSAttributedString(string: "")
////				textView.typingAttributes[.foregroundColor] = UIColor.label
////			}
////			textView.undoManager?.registerUndo(withTarget: self, handler: { targetSelf in
////				print("Doing undo")
////			})
//
//			let selectedRange = textView.selectedRange
//			textView.selectedRange = NSRange()
//			textView.selectedRange = selectedRange
//		}
//
//		func textViewDidEndEditing(_ textView: UITextView) {
////			if textView.attributedText.string == "" || textView.attributedText.string == parent.placeholder {
////				textView.attributedText = NSAttributedString(string: parent.placeholder)
////			} else {
////				parent.onCommit(textView.attributedText)
////			}
//			UITextView.appearance().tintColor = .tintColor
//		}
//	}
