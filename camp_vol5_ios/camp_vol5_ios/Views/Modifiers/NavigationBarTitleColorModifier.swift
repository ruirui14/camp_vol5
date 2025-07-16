import SwiftUI

struct NavigationBarTitleColorModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                appearance.titleTextAttributes = [.foregroundColor: UIColor(color)]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(color)]

                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

extension View {
    func navigationBarTitleTextColor(_ color: Color) -> some View {
        self.modifier(NavigationBarTitleColorModifier(color: color))
    }
}
