import SwiftUI

struct DismissButton: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: Size.dismissIcon, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            .tint(Color.surface)
        }
    }
}
