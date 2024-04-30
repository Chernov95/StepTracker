//
//  ProgressBar.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import SwiftUI

//struct ProgressBar: View {
//    var width: CGFloat = 200
//    var height: CGFloat = 20
//    var percent: CGFloat = 69
//    var color1: Color = .orange
//    var color2: Color = .pink
//    var body: some View {
//        let multiplier = width / 100
//        ZStack(alignment: .leading) {
//            RoundedRectangle(cornerRadius: height, style: .continuous)
//                .frame(width: width, height: height)
//            .foregroundColor(Color.black.opacity(0.1))
//            RoundedRectangle(cornerRadius: height, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
//                .frame(width: percent * multiplier, height: height)
//                .background(
//                    LinearGradient(gradient: Gradient(colors: [color1, color2]), startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/)
//                        .clipShape(RoundedRectangle(cornerRadius: height, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/))
//                )
//                .foregroundColor(.clear)
//        }
//    }
//}


struct ProgressBar: View {
    private let width: CGFloat = 300
    private let height: CGFloat = 50
    var percent: CGFloat = 69
    
    var body: some View {
        let multiplier = width / 100
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .frame(width: width, height: height)
            .foregroundColor(Color.black.opacity(0.1))
            RoundedRectangle(cornerRadius: height, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
                .frame(width: percent * multiplier, height: height)
                .background(
                    Color.blue
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/))
                )
                .foregroundColor(.clear)
        }
    }
}

#Preview {
    ProgressBar()
}
