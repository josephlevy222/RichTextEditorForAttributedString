//
//  KeyBoardAccessoryView.swift
//  RichTextEditor
//
//  Created by Joseph Levy on 9/10/23.
//

import SwiftUI

public struct KeyboardToolbar  {
    
    var textView: RichTextView
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var isStrikethrough: Bool = false
    var isSuperscript: Bool = false
    var isSubscript: Bool = false
    var fontSize: CGFloat = 17
	var textAlignment: NSTextAlignment = .center
    var color : Color = Color(uiColor: .label)
    var background: Color = Color(uiColor: .clear)
    
    var justChanged: Bool = false
}

extension NSTextAlignment {
	var imageName: String {
		switch self {
		case .left: "text.alignleft"
		case .center: "text.aligncenter"
		case .right: "text.alignright"
		case .justified: "text.natural"
		case .natural: "text.alignleft"
		@unknown default: "text.aligncenter"
		}
	}
	static let available: [NSTextAlignment] = [.left, .right, .center]
}

enum KeyboardCommand : Identifiable {
	case bold,italic,underline,strikethrough,superscript,subscripts,modifyFontSize,alignText,insertImage,selectColor,
		 selectBackground,dismissKeyboard
	var id : String { String(describing: self)}
}

public struct KeyboardAccessoryView: View {
	@Binding public var toolbar: KeyboardToolbar
	var textView: RichTextView { toolbar.textView }
	var coordinator: RichTextEditor.Coordinator { textView.delegate as! RichTextEditor.Coordinator }
	let inputClick = InputClickPlayer()
	private let buttonWidth: CGFloat = 32
	private let buttonHeight: CGFloat = 32
	private let cornerRadius: CGFloat = 6
	private let edgeInsets = EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
	private let selectedColor = UIColor.separator
	private let containerBackgroundColor: UIColor = .systemBackground
	private let toolBarsBackground: UIColor = .systemGroupedBackground
	private let colorConf = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
	private var imageConf: UIImage.SymbolConfiguration {
		UIImage.SymbolConfiguration(pointSize: min(buttonWidth, buttonHeight) * 0.7)
	}
	var attributes: [NSAttributedString.Key : Any] { textView.typingAttributes }
	
	func roundedRectangle(_ highlight: Bool = false) -> some View {
		RoundedRectangle(cornerRadius: cornerRadius).fill(Color(highlight ? selectedColor : .clear))
			.frame(width: buttonWidth, height: buttonHeight)
	}
	
	func updateAttributedText(with attributedText: NSAttributedString) {
		let selection = textView.selectedRange
		textView.updateAttributedText(with: attributedText)
		textView.selectedRange = selection
	}
	
	func keyboardButtonView(_ button: KeyboardCommand) -> some View {
		func symbol(_ name: String) -> Image { .init(systemName: name) }
		func space(_ width: CGFloat) -> some View { Color.clear.frame(width: width)}
		return HStack(spacing: 1) {
			switch button {
			case .bold:
				Button(action: toggleBoldface) { symbol("bold") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isBold))
			case .italic:
				Button(action: toggleItalics) { symbol("italic") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isItalic))
			case .underline:
				Button(action: toggleUnderline) { symbol("underline") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isUnderline))
			case .strikethrough:
				Button(action: toggleStrikethrough) { symbol("strikethrough") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isStrikethrough))
			case .superscript:
				Button(action: toggleSuperscript) { symbol("textformat.superscript") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isSuperscript))
			case .subscripts:
				Button(action: toggleSubscript) { symbol("textformat.subscript") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isSubscript))
			case .modifyFontSize:
				Divider()
				space(4)
				HStack(spacing: 4) {
					Button(action: increaseFontSize) { symbol("plus.circle") }
					Text(String(format: "%.1f", toolbar.fontSize)).font(.body)
					Button(action: decreaseFontSize) { symbol("minus.circle") }
				}
				space(4)
				Divider()
			case .alignText:
				Button(action: alignText) { symbol(toolbar.textAlignment.imageName)}
			case .insertImage:
				Button(action: insertImage) { symbol("photo.on.rectangle.angled") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle())
			case .selectColor:
				space(5)
				ColorPicker(selection: $toolbar.color, supportsOpacity: true) {
					Button(action: selectColor) { symbol("character") } }
				.fixedSize()
				space(5)
			case .selectBackground:
				space(5)
				ColorPicker(selection: $toolbar.background, supportsOpacity: true) {
					Button(action: selectBackground) { symbol("a.square") } }
				.fixedSize()
				space(5)
			case .dismissKeyboard:
				Button(action: {
					textView.resignFirstResponder()
				}) { symbol("keyboard.chevron.compact.down")}
					.padding(edgeInsets)
			}
			
		}
	}
		
	func keyboardButtons(_ buttons: [KeyboardCommand]) -> some View {
		HStack(spacing: 1) {
			ForEach(buttons) { keyboardButtonView($0) }
		}
	}
	
	let leadingButtons: [KeyboardCommand] = [.bold,.italic,.underline,.strikethrough,.superscript,.subscripts,.modifyFontSize,
											 .selectColor,.selectBackground,.alignText]
	let trailingButtons: [KeyboardCommand] = [.dismissKeyboard]
    
	public var body: some View {
		HStack(spacing: 1) {
			ScrollView(.horizontal){
				keyboardButtons(leadingButtons)
			}
			Spacer()
			keyboardButtons(trailingButtons)
		}
        .background(Color(toolBarsBackground))
    }
	
    var attributedText: NSAttributedString { textView.attributedText }
    var selectedRange: NSRange { textView.selectedRange }
    
    func toggleStrikethrough() {
		inputClick.play()
        let attributedString = NSMutableAttributedString(attributedString: attributedText)
        if selectedRange.isEmpty {
            toolbar.isStrikethrough.toggle()
            textView.typingAttributes[.strikethroughStyle] = toolbar.isStrikethrough ? NSUnderlineStyle.single.rawValue : nil
            toolbar.justChanged = true
            if let didChangeSelection = textView.delegate?.textViewDidChangeSelection { didChangeSelection(textView) }
            return
        }
        var isAllStrikethrough = true
        attributedString.enumerateAttribute(.strikethroughStyle,
                                            in: selectedRange,
                                            options: []) { (value, range, stopFlag) in
            let strikethrough = value as? NSNumber
            if strikethrough == nil {
                isAllStrikethrough = false
                stopFlag.pointee = true
            }
        }
        if isAllStrikethrough {
            attributedString.removeAttribute(.strikethroughStyle, range: selectedRange)
        } else {
            attributedString.addAttribute(.strikethroughStyle, value: 1, range: selectedRange)
        }
        updateAttributedText(with: attributedString)
    }
    
    func toggleUnderline() {
		inputClick.play()
        let attributedString = NSMutableAttributedString(attributedString: attributedText)
        if selectedRange.isEmpty {
            toolbar.isUnderline.toggle()
            textView.typingAttributes[.underlineStyle] = toolbar.isUnderline ? NSUnderlineStyle.single.rawValue : nil
            toolbar.justChanged = true
            if let didChangeSelection = textView.delegate?.textViewDidChangeSelection { didChangeSelection(textView) }
            return
        }
        var isAllUnderlined = true
        attributedString.enumerateAttribute(.underlineStyle,
                                            in: selectedRange,
                                            options: []) { (value, range, stopFlag) in
            let underline = value as? NSNumber
            if  underline == nil  {
                isAllUnderlined = false
                stopFlag.pointee = true
            }
        }
        if isAllUnderlined {
            // Bug in iOS 15 when all selected and underlined that I can't fix as yet
            attributedString.removeAttribute(.underlineStyle, range: selectedRange)
        } else {
            attributedString.addAttribute(.underlineStyle,
                                          value: NSUnderlineStyle.single.rawValue,
                                          range: selectedRange)
        }
        updateAttributedText(with: attributedString)
    }

    func toggleBoldface() {
		toggleSymbolicTrait(.traitBold)
    }
    
    func toggleItalics() {
		toggleSymbolicTrait(.traitItalic)
    }
	
    private func toggleSymbolicTrait(_ trait: UIFontDescriptor.SymbolicTraits)  {
		inputClick.play()
        if selectedRange.isEmpty { // toggle typingAttributes
            toolbar.justChanged = true
            let uiFont = textView.typingAttributes[.font] as? UIFont
            if let descriptor = uiFont?.fontDescriptor {
                let isBold = descriptor.symbolicTraits.intersection(.traitBold) == .traitBold
                let isTrait = descriptor.symbolicTraits.intersection(trait) == trait
                // Fix bug in largeTitle by setting bold weight directly
                var weight = isBold ? .bold : descriptor.weight
                weight = trait != .traitBold ? weight : (isBold ? .regular : .bold)
                if let fontDescriptor = isTrait ? descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
                    : descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait)) {
                    textView.typingAttributes[.font] = UIFont(descriptor: fontDescriptor.withWeight(weight), 
															  size: descriptor.pointSize)
                }
                if let didChangeSelection = textView.delegate?.textViewDidChangeSelection { didChangeSelection(textView) }
			} 
            
        } else {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAll = true
            attributedString.enumerateAttribute(.font, in: selectedRange,
                                                options: []) { (value, range, stopFlag) in
                let uiFont = value as? UIFont
                if let descriptor = uiFont?.fontDescriptor {
					let isTrait = (descriptor.symbolicTraits.intersection(trait) == trait)
                    isAll = isAll && isTrait
                    if !isAll { stopFlag.pointee = true }
                }
            }
            attributedString.enumerateAttribute(.font, in: selectedRange,
                                                options: []) {(value, range, stopFlag) in
                let uiFont = value as? UIFont
                if  let descriptor = uiFont?.fontDescriptor {
                    // Fix bug in largeTitle by setting bold weight directly
                    var weight = descriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : descriptor.weight
                    weight = trait != .traitBold ? weight : (isAll ? .regular : .bold)
                    if let fontDescriptor = isAll ? descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
                        : descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait)) {
                        attributedString.addAttribute(.font, value: UIFont(descriptor: fontDescriptor.withWeight(weight),
                                                                           size: descriptor.pointSize), range: range)
                    }
                }
            }
            updateAttributedText(with: attributedString)
        }
    }
    
    private func toggleSubscript() {
        toolbar.isSubscript.toggle()
        toggleScript(sub: true)
    }
    
    private func toggleSuperscript() {
        toolbar.isSuperscript.toggle()
        toggleScript(sub: false)
    }
    
    private func toggleScript(sub: Bool = false) {
		inputClick.play()
        let selectedRange = textView.selectedRange
        let newOffset = sub ? -0.3 : 0.4
        let attributedString = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.isEmpty { // toggle typingAttributes
            var fontSize = toolbar.fontSize
            if toolbar.isSubscript && toolbar.isSuperscript { // Both on
                // Turn one off
                if sub { toolbar.isSuperscript = false } else { toolbar.isSubscript = false }
                // Check that baseline is offset the right way
                textView.typingAttributes[.baselineOffset] = newOffset*toolbar.fontSize
                // font is already right
            }
            if !toolbar.isSubscript && !toolbar.isSuperscript {
                // Both set off so adjust baseline and font
                textView.typingAttributes[.baselineOffset] = nil
                // use toolbar.fontSize
            } else {  // One is on
                toolbar.textView.typingAttributes[.baselineOffset] = newOffset*toolbar.fontSize
                fontSize *= 0.75
            }
            var newFont : UIFont
            let descriptor: UIFontDescriptor
            if let font = textView.typingAttributes[.font] as? UIFont {
                descriptor = font.fontDescriptor
				//let traits = descriptor.symbolicTraits.union(.traitTightLeading)
				
                newFont = UIFont(descriptor: descriptor, size: fontSize)
                if descriptor.symbolicTraits.intersection(.traitItalic) == .traitItalic, let font = newFont.italic() {
                    newFont = font
                }
				
            } else { newFont = UIFont.preferredFont(forTextStyle: .body) }
            textView.typingAttributes[.font] =  newFont
            toolbar.justChanged = true
            if let didChangeSelection = textView.delegate?.textViewDidChangeSelection { didChangeSelection(textView) }
            return
        }
        var isAllScript = true
        attributedString.enumerateAttributes(in: selectedRange,
                                             options: []) { (attributes, range, stopFlag) in
            let offset = attributes[.baselineOffset] as? CGFloat ?? 0.0
            if offset == 0.0 { //  normal
                isAllScript = false
            } else { // its super or subscript so set to normal
                // Enlarge font and remove baselineOffset
                var newFont : UIFont
                let descriptor: UIFontDescriptor
                if let font = attributes[.font] as? UIFont {
                    descriptor = font.fontDescriptor
                    newFont = UIFont(descriptor: descriptor, size: descriptor.pointSize/0.75)
                    attributedString.removeAttribute(.baselineOffset, range: range)
                    attributedString.removeAttribute(.font, range: range)
                    if descriptor.symbolicTraits.intersection(.traitItalic) == .traitItalic, let font = newFont.italic() {
                        newFont = font
                    }
                } else { newFont = UIFont.preferredFont(forTextStyle: .body) }
                attributedString.addAttribute(.font, value: newFont, range: range)
            }
        }
        // Now attributedString is free of scripts so if isAllScript we are done
        if !isAllScript {
            // set to script
            attributedString.enumerateAttributes(in: selectedRange,
                                                 options: []) {(attributes, range, stopFlag) in
                var newFont : UIFont
                let descriptor: UIFontDescriptor
                if let font = attributes[.font] as? UIFont {
                    let isBold = font.contains(trait: .traitBold)
					descriptor = font.fontDescriptor
						.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.traitTightLeading)) ?? font.fontDescriptor
                    attributedString.addAttribute(.baselineOffset, value: newOffset*descriptor.pointSize,
                                                  range: range)
                    newFont = UIFont(descriptor: descriptor, size: 0.75*descriptor.pointSize)
                    if descriptor.symbolicTraits.intersection(.traitItalic) == .traitItalic, let font = newFont.italic() {
                        newFont = isBold ? font.withWeight(.bold) : font
                    }
                } else { newFont = UIFont.preferredFont(forTextStyle: .body) }
                attributedString.addAttribute(.font, value: newFont, range: range)
            }
        }
        updateAttributedText(with: attributedString)
    }
    
    
    private func alignText() {
		inputClick.play()
		toolbar.textAlignment = switch toolbar.textAlignment {
			case .left: .center
			case .center: .right
			case .right: .left
			case .justified: .justified
			case .natural: .center
			@unknown default: .left
		}
		textView.textAlignment = toolbar.textAlignment
        if let update = textView.delegate?.textViewDidChange {
            update(textView)
        }
    }
    
    /// Add text attribute to text view
    private func textEffect<T: Equatable>(range: NSRange, key: NSAttributedString.Key, value: T, defaultValue: T) {
		inputClick.play()
        if !range.isEmpty {
            let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
            mutableString.removeAttribute(key, range: range)
            mutableString.addAttributes([key : value], range: range)
            // Update parent
            textView.updateAttributedText(with: mutableString)
        } else { print("empty texteffect")
            if let current = textView.typingAttributes[key], current as! T == value  {
                textView.typingAttributes[key] = defaultValue
            } else {
                textView.typingAttributes[key] = value
            }
        }
        textView.selectedRange = range // restore selection
    }
    
    private func adjustFontSize(isIncrease: Bool) {
		inputClick.play()
        let textRange = textView.selectedRange
        var selectedRangeAttributes: [(NSRange, [NSAttributedString.Key : Any])] {
            var textAttributes: [(NSRange, [NSAttributedString.Key : Any])] = []
            if textRange.isEmpty {
                textAttributes = [(textRange, textView.typingAttributes)]
            } else {
                textView.attributedText.enumerateAttributes(in: textRange) { attributes, range, stop in
                    textAttributes.append((range,attributes))
                }
            }
            return textAttributes
        }
        var font: UIFont
        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        let maxFontSize: CGFloat = 80
        let minFontSize: CGFloat = 8
        let rangesAttributes = selectedRangeAttributes
        if textRange.isEmpty {
            font = selectedRangeAttributes[0].1[.font] as? UIFont ?? defaultFont
            let offset = selectedRangeAttributes[0].1[.baselineOffset] as? CGFloat ?? 0.0
            let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : font
				.fontDescriptor.weight
            let size = toolbar.fontSize
            let fontSize = Int(size + CGFloat(isIncrease ? (size < maxFontSize ? 1 : 0) : (size > minFontSize ? -1 : 0))+0.5)
            font = UIFont(descriptor: font.fontDescriptor, size: CGFloat(fontSize) * (offset == 0 ? 1.0 : 0.75) )
				.withWeight(weight)
            textView.typingAttributes[.font] = font
            toolbar.fontSize = CGFloat(fontSize)
        } else {
            for (range, attributes) in rangesAttributes {
                font = attributes[.font] as? UIFont ?? defaultFont
                let offset = selectedRangeAttributes[0].1[.baselineOffset] as? CGFloat ?? 0.0
                let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : font.fontDescriptor.weight
                let size = font.fontDescriptor.pointSize / (offset == 0 ? 1.0 : 0.75 )
                let fontSize = Int(size + CGFloat(isIncrease ? (size<maxFontSize ? 1 : 0) : (size>minFontSize ? -1 : 0))+0.5)
                font = UIFont(descriptor: font.fontDescriptor, size: CGFloat(fontSize) * (offset == 0 ? 1.0 : 0.75) )
					.withWeight(weight)
                textEffect(range: range, key: .font, value: font, defaultValue: defaultFont)
            }
        }
        textView.selectedRange = textRange // restore range
    }
    
    private func increaseFontSize() {
        adjustFontSize(isIncrease: true)
    }
    
    private func decreaseFontSize() {
        adjustFontSize(isIncrease: false)
    }
    
    func insertImage() {
		inputClick.play()
		let delegate = textView.delegate as? RichTextEditor.Coordinator
		delegate?.insertImage()
    }
    
    // MARK: - Color Selection Button Actions
    private func selectColor() {
        let color = UIColor(toolbar.color)
        textEffect(range: textView.selectedRange, key: .foregroundColor, value: color, defaultValue: color)
    }
    
    private func selectBackground() {
        let color = UIColor(toolbar.background)
        textEffect(range: textView.selectedRange, key: .backgroundColor, value: color, defaultValue: color)
    }
}

struct KeyBoardAddition_Previews: PreviewProvider {
    @State static var toolbar: KeyboardToolbar = .init(textView: RichTextView(), isUnderline: true)
    static var previews: some View {
        KeyboardAccessoryView(toolbar: .constant(toolbar))
    }
}

import AVFoundation
public class InputClickPlayer {
	private var soundID: SystemSoundID
	init() {
		soundID = 0
		if let filePath = Bundle.main.path(forResource: "sound56", ofType: "wav") {
						//Bundle.module.path(forResource: "sound56", ofType: "wav") {
			let fileURL = URL(fileURLWithPath: filePath)
			AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
		} else { debugPrint("Error getting button click file sound56.wav") }
	}
	
	public func play() { AudioServicesPlaySystemSound(soundID) }
}

extension RichTextEditor.Coordinator : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	// MARK: - Image Picker
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, var image = img.roundedImageWithBorder(color: .secondarySystemBackground) {
			//textViewDidBeginEditing(parent.textView)
			let newString = NSMutableAttributedString(attributedString: parent.textView.attributedText)
			image = scaleImage(image: image, maxWidth: 180, maxHeight: 180)
			
			let textAttachment = NSTextAttachment(image: image)
			let attachmentString = NSAttributedString(attachment: textAttachment)
			newString.append(attachmentString)
			parent.textView.attributedText = newString
			textViewDidChange(parent.textView)
		}
		picker.dismiss(animated: true, completion: nil)
	}
	
	func scaleImage(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
		let ratio = image.size.width / image.size.height
		let imageW: CGFloat = (ratio >= 1) ? maxWidth : image.size.width*(maxHeight/image.size.height)
		let imageH: CGFloat = (ratio <= 1) ? maxHeight : image.size.height*(maxWidth/image.size.width)
		UIGraphicsBeginImageContext(CGSize(width: imageW, height: imageH))
		image.draw(in: CGRect(x: 0, y: 0, width: imageW, height: imageH))
		let scaledimage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return scaledimage!
	}
	
	// MARK: - Text Editor Delegate
	
	func adjustFontSize(isIncrease: Bool) {
		var font: UIFont
		let defaultFont = UIFont.preferredFont(forTextStyle: .body)
		let maxFontSize: CGFloat = 80
		let minFontSize: CGFloat = 8
		let rangesAttributes = selectedRangeAttributes
		for (range, attributes) in rangesAttributes {
			font = attributes[.font] as? UIFont ?? defaultFont
			let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : font.fontDescriptor.weight
			let size = font.fontDescriptor.pointSize
			let fontSize = size + CGFloat(isIncrease ? (size < maxFontSize ? 1 : 0) : (size > minFontSize ? -1 : 0))
			font = UIFont(descriptor: font.fontDescriptor, size: fontSize).withWeight(weight)
			textEffect(range: range, key: .font, value: font, defaultValue: defaultFont)
		}
	}
	
	/// Not used yet?
	func textFont(name: String) {
		let attributes = parent.textView.selectedRange.isEmpty ? parent.textView.typingAttributes : selectedAttributes
		let fontSize = getFontSize(attributes: attributes)
		
		let fontName = name
		let defaultFont = UIFont.preferredFont(forTextStyle: .body)
		let newFont = UIFont(name: fontName, size: fontSize) ?? defaultFont
		textEffect(range: parent.textView.selectedRange, key: .font, value: newFont, defaultValue: defaultFont)
	}
	
	func textColor(color: UIColor) {
		textEffect(range: parent.textView.selectedRange, key: .foregroundColor, value: color, defaultValue: color)
	}
	
	func textBackground(color: UIColor) {
		textEffect(range: parent.textView.selectedRange, key: .backgroundColor, value: color, defaultValue: color)
	}
	
	func insertImage() {
		let sourceType = UIImagePickerController.SourceType.photoLibrary
		let imagePicker = UIImagePickerController()
		imagePicker.delegate = self
		imagePicker.allowsEditing = true
		imagePicker.sourceType = sourceType
		parent.textView.parentViewController?.present(imagePicker, animated: true, completion: nil)
	}
	
	func insertLine(name: String) {
		if let line = UIImage(named: name) {
			let newString = NSMutableAttributedString(attributedString: parent.textView.attributedText)
			let image = scaleImage(image: line, maxWidth: 280, maxHeight: 20)
			let attachment = NSTextAttachment(image: image)
			let attachedString = NSAttributedString(attachment: attachment)
			newString.append(attachedString)
			parent.textView.attributedText = newString
		}
	}
	
	func hideKeyboard() {
		parent.textView.resignFirstResponder()
	}
	
	/// Add text attribute to text view
	private func textEffect<T: Equatable>(range: NSRange, key: NSAttributedString.Key, value: T, defaultValue: T) {
		if !range.isEmpty {
			let mutableString = NSMutableAttributedString(attributedString: parent.textView.attributedText)
			mutableString.removeAttribute(key, range: range)
			mutableString.addAttributes([key : value], range: range)
			parent.textView.updateAttributedText(with: mutableString)
		} else {
			if let current = parent.textView.typingAttributes[key], current as! T == value  {
				parent.textView.typingAttributes[key] = defaultValue
			} else {
				parent.textView.typingAttributes[key] = value
			}
		}
		parent.textView.selectedRange = range // restore selection
	}
	
	private func getFontSize(attributes: [NSAttributedString.Key : Any]) -> CGFloat {
		let font = attributes[.font] as? UIFont ?? UIFont.preferredFont(forTextStyle: .body)
		return font.pointSize
	}
	
	var selectedAttributes: [NSAttributedString.Key : Any] {
		let textRange = parent.textView.selectedRange
		var textAttributes = parent.textView.typingAttributes
		if !textRange.isEmpty {
			//textAttributes = [:] // Uncomment to avoid system putting values in typingAttributes
			parent.textView.attributedText.enumerateAttributes(in: textRange) { attributes, range, stop in
				for item in attributes {
					textAttributes[item.key] = item.value
				}
			}
		}
		return textAttributes
	}
	
	var selectedRangeAttributes: [(NSRange, [NSAttributedString.Key : Any])] {
		let textRange = parent.textView.selectedRange
		if textRange.isEmpty { return [(textRange, parent.textView.typingAttributes)]}
		var textAttributes: [(NSRange, [NSAttributedString.Key : Any])] = []
		parent.textView.attributedText.enumerateAttributes(in: textRange) { attributes, range, stop in
			textAttributes.append((range,attributes))
		}
		return textAttributes
	}
	
	// MARK: - Text View Delegate
	func textViewDidChangeSelection(_ textView: UITextView) {
		let attributes = selectedAttributes
		var updateFunc = {}
		let richTextView = textView as? RichTextView
		//let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
		let fontTraits: (isBold: Bool,isItalic: Bool,fontSize: CGFloat, offset: CGFloat) = {
			let offset = attributes[.baselineOffset] as? CGFloat ?? 0.0
			let pointSize: CGFloat
			let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits
			let bold = traits?.intersection(.traitBold).contains(.traitBold) ?? false
			let italic = traits?.intersection(.traitItalic).contains(.traitItalic) ?? false
			
			if let toolbar = richTextView?.toolbar, toolbar.wrappedValue.justChanged {
				pointSize = toolbar.wrappedValue.fontSize
				return ( bold, italic, pointSize, offset)
			} else {
				if let font=attributes[.font] as? UIFont {
					pointSize = font.pointSize / (offset == 0.0 ? 1.0 : 0.75)
					// pointSize is the fontSize that the toolbar ought to use unless justChanged
					return (font.contains(trait: .traitBold),font.contains(trait: .traitItalic), pointSize, offset)
				}
				//print("Non UIFont may be Font in \(parent.textView.attributedText), try to convert...")
				
				// Try to convert Font to UIFont
				if let font = attributes[.font] as? Font { // { was ,
					let uiFont = //UIFont(font: font, traitCollection: .current)
					font.uiFont() ?? UIFont.preferredFont(forTextStyle: .body)
					pointSize = uiFont.pointSize / (offset == 0.0 ? 1.0 : 0.75)
					// pointSize is the fontSize that the toolbar ought to use unless justChanged
					return (uiFont.contains(trait: .traitBold),uiFont.contains(trait: .traitItalic), pointSize, offset)
				}
				pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
				print("Non UIFont in fontTraits default pointSize is \(pointSize)")
				
				// Fix font
				let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
				var font: UIFont
				let defaultFont = UIFont.preferredFont(forTextStyle: .body)
				//let selection = textView.selectedRange
				//textView.selectedRange = NSRange(location: 0,length: textView.attributedText.length)
				let rangesAttributes = selectedRangeAttributes
				for (range, attributes) in rangesAttributes {
					font = attributes[.font] as? UIFont ?? defaultFont
					let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold
					? .bold : font.fontDescriptor.weight
					let size = font.fontDescriptor.pointSize
					font = UIFont(descriptor: font.fontDescriptor, size: size).withWeight(weight)
					mutableString.removeAttribute(.font, range: range)
					mutableString.addAttributes([.font : font], range: range)
				}
				updateFunc = {(textView as? RichTextView)?.updateAttributedText(with: mutableString)}
			}
			return ( false, false, pointSize, offset)
		}()
		
		var isUnderline: Bool {
			guard let toolbar = richTextView?.toolbar else { return false }
			return toolbar.wrappedValue.justChanged ? toolbar.wrappedValue.isUnderline : {
				if let style = attributes[.underlineStyle] as? Int {
					return style == NSUnderlineStyle.single.rawValue // or true
				} else {
					return false
				}
			}()
		}
		
		var isStrikethrough: Bool {
			guard let toolbar = richTextView?.toolbar else { return false }
			return toolbar.wrappedValue.justChanged ? toolbar.wrappedValue.isStrikethrough : {
				if let style = attributes[.strikethroughStyle] as? Int {
					return style == NSUnderlineStyle.single.rawValue
				} else {
					return false
				}
			}()
		}
		
		var isScript: (sub: Bool,super: Bool) {
			guard let toolbar = richTextView?.toolbar else { return (false, false) }
			return toolbar.wrappedValue.justChanged
			? (toolbar.wrappedValue.isSubscript, toolbar.wrappedValue.isSuperscript)
			: (fontTraits.offset < 0.0, fontTraits.offset > 0.0)
		}
		
		var color: UIColor { selectedAttributes[.foregroundColor] as? UIColor ?? UIColor.label }
		var background: UIColor  { selectedAttributes[.backgroundColor] as? UIColor ?? UIColor.systemBackground }
		
		if let color = parent.textView.typingAttributes[.backgroundColor] as? UIColor, color.luminance < 0.55 {
			textView.tintColor =  .cyan
		} else {
			textView.tintColor = .tintColor
		}
		DispatchQueue.main.async {
			guard let toolbar = richTextView?.toolbar else {  return }
			toolbar.wrappedValue.fontSize = fontTraits.fontSize
			toolbar.wrappedValue.isBold = fontTraits.isBold
			toolbar.wrappedValue.isItalic = fontTraits.isItalic
			toolbar.wrappedValue.isUnderline = isUnderline
			toolbar.wrappedValue.isStrikethrough = isStrikethrough
			let script = isScript
			toolbar.wrappedValue.isSuperscript = script.1 //isSuperscript
			toolbar.wrappedValue.isSubscript = script.0 //isSubscript
			toolbar.wrappedValue.color = Color(uiColor: color)
			toolbar.wrappedValue.background = Color(uiColor: background)
			toolbar.wrappedValue.justChanged = false
			toolbar.wrappedValue.textAlignment = textView.textAlignment
			updateFunc()
		}
	}
	
}
//	func textViewDidChangeSelection1(_ textView: UITextView) {
//		print("text did change selection")
//		let attributes = selectedAttributes
//		let richTextView = textView as? RichTextView
//		let fontTraits: (isBold: Bool,isItalic: Bool,fontSize: CGFloat, offset: CGFloat) = {
//			let offset = attributes[.baselineOffset] as? CGFloat ?? 0.0
//			let pointSize: CGFloat
//			let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits
//			let bold = traits?.intersection(.traitBold).contains(.traitBold) ?? false
//			let italic = traits?.intersection(.traitItalic).contains(.traitItalic) ?? false
//			if let toolbar = richTextView?.toolbar, toolbar.wrappedValue.justChanged {
//				pointSize = toolbar.wrappedValue.fontSize
//				return ( bold, italic, pointSize, offset)
//			} else {
//				if let font=attributes[.font] as? UIFont {
//					pointSize = font.pointSize / (offset == 0.0 ? 1.0 : 0.75)
//					// pointSize is the fontSize that the toolbar ought to use unless justChanged
//					return (font.contains(trait: .traitBold),font.contains(trait: .traitItalic), pointSize, offset)
//				}
//				print("Non UIFont may be Font in \(parent.attributedText), try to convert...")
//				// Try to convert Font to UIFont
//				if let font = attributes[.font] as? Font,
//				   let uiFont = font.uiFont() {
//					pointSize = uiFont.pointSize / (offset == 0.0 ? 1.0 : 0.75)
//					// pointSize is the fontSize that the toolbar ought to use unless justChanged
//					return (uiFont.contains(trait: .traitBold),uiFont.contains(trait: .traitItalic), pointSize, offset)
//				}
//				pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
//				print("Non UIFont in fontTraits default pointSize is \(pointSize)")
//				
//				// Fix font
//				DispatchQueue.main.async {
//					let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
//					var font: UIFont
//					let defaultFont = UIFont.preferredFont(forTextStyle: .body)
//					let selection = textView.selectedRange
//					textView.selectedRange = NSRange(location: 0,length: textView.attributedText.length)
//					let rangesAttributes = self.selectedRangeAttributes
//					for (range, attributes) in rangesAttributes {
//						font = attributes[.font] as? UIFont ?? defaultFont
//						let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold
//						? .bold : font.fontDescriptor.weight
//						let size = font.fontDescriptor.pointSize
//						font = UIFont(descriptor: font.fontDescriptor, size: size).withWeight(weight)
//						mutableString.removeAttribute(.font, range: range)
//						mutableString.addAttributes([.font : font], range: range)
//					}
//					(textView as? RichTextView)?.updateAttributedText(with: mutableString)
//					textView.selectedRange = selection ; print("selectedRange = \(selection)")
//				}
//			}
//			return ( false, false, pointSize, offset)
//		}()
//		
//		var isUnderline: Bool {
//			guard let toolbar = richTextView?.toolbar else { return false }
//			return toolbar.wrappedValue.justChanged ? toolbar.wrappedValue.isUnderline : {
//				if let style = attributes[.underlineStyle] as? Int {
//					return style == NSUnderlineStyle.single.rawValue // or true
//				} else {
//					return false
//				}
//			}()
//		}
//		
//		var isStrikethrough: Bool {
//			guard let toolbar = richTextView?.toolbar else { return false }
//			return toolbar.wrappedValue.justChanged ? toolbar.wrappedValue.isStrikethrough : {
//				if let style = attributes[.strikethroughStyle] as? Int {
//					return style == NSUnderlineStyle.single.rawValue
//				} else {
//					return false
//				}
//			}()
//		}
//		
//		var isScript: (sub: Bool,super: Bool) {
//			guard let toolbar = richTextView?.toolbar else { return (false, false) }
//			return toolbar.wrappedValue.justChanged
//			? (toolbar.wrappedValue.isSubscript, toolbar.wrappedValue.isSuperscript)
//			: (fontTraits.offset < 0.0, fontTraits.offset > 0.0)
//		}
//		
//		var color: UIColor { selectedAttributes[.foregroundColor] as? UIColor ?? UIColor.label }
//		var background: UIColor  { selectedAttributes[.backgroundColor] as? UIColor ?? UIColor.systemBackground }
//		
//		if let color = parent.textView.typingAttributes[.backgroundColor] as? UIColor, color.luminance < 0.55 {
//			textView.tintColor =  .cyan
//		} else {
//			textView.tintColor = .tintColor
//		}
//		DispatchQueue.main.async { //[self] in
//			guard let toolbar = richTextView?.toolbar else {  return }
//			toolbar.wrappedValue.fontSize = fontTraits.fontSize
//			toolbar.wrappedValue.isBold = fontTraits.isBold
//			toolbar.wrappedValue.isItalic = fontTraits.isItalic
//			toolbar.wrappedValue.isUnderline = isUnderline
//			toolbar.wrappedValue.isStrikethrough = isStrikethrough
//			let script = isScript
//			toolbar.wrappedValue.isSuperscript = script.1 //isSuperscript
//			toolbar.wrappedValue.isSubscript = script.0 //isSubscript
//			toolbar.wrappedValue.color = Color(uiColor: color)
//			toolbar.wrappedValue.background = Color(uiColor: background)
//			toolbar.wrappedValue.justChanged = false
//			toolbar.wrappedValue.textAlignment = textView.textAlignment
//		}
//	}
	
//	func textViewDidBeginEditing(_ textView: UITextView) {
//		if textView.attributedText.string == parent.placeholder {
//			textView.attributedText = NSAttributedString(string: "")
//			textView.typingAttributes[.foregroundColor] = UIColor.label
//		}
//		textView.undoManager?.registerUndo(withTarget: self, handler: { targetSelf in
//			print("Doing undo")
//		})
//		
//		let selectedRange = textView.selectedRange
//		textView.selectedRange = NSRange()
//		textView.selectedRange = selectedRange
//	}
//	
//	func textViewDidEndEditing(_ textView: UITextView) {
//		if textView.attributedText.string == "" || textView.attributedText.string == parent.placeholder {
//			textView.attributedText = NSAttributedString(string: parent.placeholder)
//		} else {
//			parent.onCommit(textView.attributedText)
//		}
//		UITextView.appearance().tintColor = .tintColor
//	}
	
//	func textViewDidChange(_ textView: UITextView) {
//		
//		if textView.attributedText.string != parent.placeholder {
//			self.parent.attributedText = textView.attributedText.uiFontAttributedString
//		}
//		
//		textViewDidChangeSelection(textView)
//	}
//
//}

