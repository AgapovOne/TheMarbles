import SwiftUI
import Combine

struct ContentView: View {

    @State var displayHelp: Bool = false
    
    let content: [OperatorCollection] = [
        .map,
        .filter,
        .reduce,
        .mathematical,
        .matching,
        .sequence,
        .select,
        .combine,
        .timing
    ]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(content, id: \.name) { section in
                    Section(
                        header: ListHeader(text: section.name)
                    ) {
                        ForEach(section.operators, id: \.name) {
                            NavigationLink(
                                $0.name,
                                destination: MarblesScreen(operation: $0)
                            )
                        }
                    }
                }
            }
#if os(iOS)
            .navigationBarTitle("Operators")
#endif
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    Button("Help") { displayHelp = true }
                }
            })
            .navigationSplitViewColumnWidth(min: 200, ideal: 300)
        } detail: {
            MarblesScreen(operation: content[0].operators[0])
        }
        .sheet(isPresented: $displayHelp, content: {
            AboutScreen() { displayHelp = false }
        })
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
