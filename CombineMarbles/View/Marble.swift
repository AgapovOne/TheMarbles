import Foundation
import SwiftUI

struct Marble: View {

    var content: String? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .frame(height: 44)
                .frame(minWidth: 44)
                .foregroundColor(.navigationBarColor)
            Text(content ?? "")
                .foregroundColor(.foreground)
                .padding(.horizontal, 6)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

}

struct Marble_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Marble(content: "44")
            Marble(content: "500000000")
        }
    }
}
