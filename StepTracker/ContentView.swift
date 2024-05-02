//
//  ContentView.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import SwiftUI
import Charts

struct ContentView: View {
    @State private var selectedTab: Tabs = .today
    private let pickerWidth: CGFloat = 200
    private let pickerContainerLeadingPadding: CGFloat = 16
    private let containerTopPadding: CGFloat = 50
    
    var body: some View {
        VStack {
            HStack {
                Picker("", selection: $selectedTab.animation()) {
                    Text(Tabs.today.rawValue)
                        .tag(Tabs.today)
                    Text(Tabs.history.rawValue)
                        .tag(Tabs.history)
                }
                .pickerStyle(.segmented)
                .frame(width: pickerWidth)
                Spacer()
            }
            .padding(.leading, pickerContainerLeadingPadding)
            Spacer()
            if selectedTab == .today {
                TodayView()
            } else {
                HistoryView()
            }
            Spacer()
        }
        .padding(.top, containerTopPadding)
    }
    private enum Tabs: String {
        case today = "Today"
        case history = "History"
    }
}

#Preview {
    ContentView()
}
