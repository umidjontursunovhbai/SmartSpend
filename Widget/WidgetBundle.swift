import WidgetKit
import SwiftUI

@main
struct SmartSpendWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmartSpendWidget()
        if #available(iOS 18.0, *) {
            SmartSpendControl()
        }
    }
}
