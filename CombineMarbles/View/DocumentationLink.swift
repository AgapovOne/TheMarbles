import SwiftUI

struct DocumentationLink: View {

    let name: String
    let url: String

    var body: some View {
        VStack {
            Divider().padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0))
            Link(destination: URL(string: url)!) {
                HStack {
                    (Text(" Documentation for ") +
                        Text(self.name)
                        .font(Font.body.bold().monospaced())
                    )
                    .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.foreground)
                }
                .padding(.vertical, 8)
            }
            Divider()
        }
    }
}
struct DocumentationLink_Previews: PreviewProvider {
    static var previews: some View {
        DocumentationLink(name: "tryRemoveDuplicates()", url: "")
    }
}
