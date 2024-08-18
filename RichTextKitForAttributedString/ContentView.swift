//
//  ContentView.swift
//  RichTextKitForAttributedString
//
//  Created by Joseph Levy on 7/16/24.
//

import SwiftUI
//extension AttributedString {
//	public func setFont(to: Font) -> AttributedString {
//		var a = self
//		a.font = to
//		return a
//	}
//}
struct ContentView: View {
	@State var text = AttributedString("Type here please").setFont(to: .largeTitle.bold())
	@State var frameWidth = 0.0
	@State var frameHeight = 0.0
	@State var fixedSizeHorizontal = false
	@State var fixedSizeVertical = false
	
    var body: some View {
		VStack {
			Text(text)
				.border(Color.red)
				.fixedSize(horizontal: fixedSizeHorizontal, vertical: fixedSizeVertical)
				.frame(width: frameWidth == 0 ? nil : frameWidth, height: frameHeight == 0 ? nil : frameHeight)
				.border(Color.green)
			Spacer()
			EditableText(text: $text)
				.border(Color.red)
				.fixedSize(horizontal: fixedSizeHorizontal, vertical: fixedSizeVertical)
				.frame(width: frameWidth == 0 ? nil : frameWidth, height: frameHeight == 0 ? nil : frameHeight)
				.border(Color.green)
			Spacer()
			Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to: nil, from: nil, for: nil) }
			Button("Reset") { text = AttributedString("Reset typing here...")}
			Spacer()
			(Text("Width: ") + Text(frameWidth != 0.0 ? "\(frameWidth)" : "nil")).font(.caption)
			Slider(value: $frameWidth, in: 0...200, step: 1)
			(Text("Height: ") + Text(frameHeight != 0.0 ? "\(frameHeight)" : "nil")).font(.caption)
			Slider(value: $frameHeight, in: 0...200, step: 1)
			Text("Fixed Size:").font(.callout)
			HStack {
				Toggle(isOn: $fixedSizeHorizontal) {Text("Horizontal").font(.caption)}
				Spacer(minLength: 20)
				Toggle(isOn: $fixedSizeVertical) {Text("Vertical").font(.caption)}
			}.fixedSize()
        }
		.padding()
		.border(.black.opacity(0.2))
		.padding()
		
    }
}

#Preview {
    ContentView()
}
