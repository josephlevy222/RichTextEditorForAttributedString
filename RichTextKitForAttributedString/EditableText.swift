//
//  EditableText.swift
//  RichTextKitForAttributedString
//
//  Created by Joseph Levy on 7/16/24.
//  Modified 7/28/24
//

import SwiftUI

struct EditableText: View {
	@Binding var text: AttributedString
	@FocusState private var focus : Bool
	@State var alignment: TextAlignment = .center // can have more global UITextView paramters
	var body: some View {
			Text(text)
				.multilineTextAlignment(alignment)
				.opacity(focus ? 0 : 1)
				.onTapGesture { focus = true }
				.overlay {
					RichTextEditor(attributedText: $text, alignment: $alignment)
						.focused($focus)
						.opacity(focus ? 1 : 0)
				}
		
	}
}

#Preview {
	struct Preview: View {
		@State var text = AttributedString("Type here...")
		@State var fixed = false
		var body: some View {
			VStack {
				EditableText(text: $text)
					.fixedSize(horizontal: fixed, vertical: fixed)
					.border(Color.green.opacity(0.5))
				Toggle(isOn: $fixed) {  Text("Fixed") }.fixedSize()
				Button("Done") {
					UIApplication.shared
						.sendAction(#selector(UIResponder.resignFirstResponder),
									to: nil, from: nil, for: nil)
				}
				Button("Reset") { text = AttributedString("Reset Type here...") }
			}
		}
	}
	return Preview()
}
