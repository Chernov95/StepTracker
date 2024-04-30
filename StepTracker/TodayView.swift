//
//  TodayView.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import SwiftUI

struct TodayView: View {
    var body: some View {
        VStack {
            Text("2654")
                .foregroundStyle(.black)
                .font(.largeTitle)
            Text("Steps")
            ProgressBar(percent: 30)
            HStack {
                Spacer()
                Text("10,000 Steps")
                    .padding(.trailing, 45)
            }
        }
    }
}

#Preview {
    TodayView()
}
