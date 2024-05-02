//
//  ProgressBar.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import SwiftUI

struct ProgressBar: View {
    private let width: CGFloat = 300
    private let height: CGFloat = 50
    @State private var animationProgress: CGFloat = 0
    var percent: Int = 69
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .frame(width: width, height: height)
                .foregroundColor(Color.black.opacity(0.1))
            
            RoundedRectangle(cornerRadius: height, style: .continuous)
                .frame(width: width * animationProgress / 100, height: height)
                .background(
                    Color.blue
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/))
                )
                .foregroundColor(.blue)
                .onAppear {
                    withAnimation(.linear(duration: 0.5)) {
                        animationProgress = CGFloat(percent)
                    }
                }
        }
    }
}

#Preview {
    ProgressBar()
}
