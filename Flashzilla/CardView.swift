//
//  CardView.swift
//  Flashzilla
//
//  Created by Сергей Захаров on 26.04.2026.
//

import SwiftUI

// Semantic drag direction for the edge tint, independent of `offset` during a spring
// (overshoot can flip the sign and flash the wrong color before returning to the center).
private enum SwipeEdge: Equatable {
    case none
    case toRight
    case toLeft

    var underlay: Color? {
        switch self {
        case .none: return nil
        case .toRight: return .green
        case .toLeft: return .red
        }
    }
}

/// White + optional green/red underlay, keyed by semantic swipe direction
/// (not the raw `offset`, so a spring that overshoots through zero can’t flash the wrong edge color).
private struct CardFrontSwipePlatter: View {
    var cornerRadius: CGFloat = 25
    var offset: CGSize
    var activeEdge: SwipeEdge
    var differentiateWithoutColor: Bool

    var body: some View {
        let base = RoundedRectangle(cornerRadius: cornerRadius)
        if differentiateWithoutColor {
            base.fill(.white)
        } else {
            base
                .fill(
                    Color.white
                        .opacity(1 - Double(abs(offset.width / 50)))
                )
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(activeEdge.underlay ?? .clear)
                }
        }
    }
}

struct CardView: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) var accessibilityDifferentiateWithoutColor
    @Environment(\.accessibilityVoiceOverEnabled) var accessibilityVoiceOverEnabled

    @State private var isShowingAnswer = false
    @State private var offset = CGSize.zero
    @State private var activeSwipeEdge: SwipeEdge = .none

    let card: Card
    /// `true` when the user got it right (e.g. swipe right); `false` when wrong (swipe left).
    var removal: ((Bool) -> Void)? = nil

    var body: some View {
        ZStack {
            CardFrontSwipePlatter(
                offset: offset,
                activeEdge: activeSwipeEdge,
                differentiateWithoutColor: accessibilityDifferentiateWithoutColor
            )
            .shadow(radius: 10)

            VStack {
                if accessibilityVoiceOverEnabled {
                    Text(isShowingAnswer ? card.answer : card.prompt)
                        .font(.largeTitle)
                        .foregroundStyle(.black)
                } else {
                    Text(card.prompt)
                        .font(.largeTitle)
                        .foregroundStyle(.black)

                    if isShowingAnswer {
                        Text(card.answer)
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .frame(width: 450, height: 250)
        .rotationEffect(.degrees(offset.width / 5.0))
        .offset(x: offset.width * 5)
        .opacity(2 - Double(abs(offset.width / 50)))
        .accessibilityAddTraits(.isButton)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    let w = gesture.translation.width
                    if abs(w) > 5 {
                        activeSwipeEdge = w > 0 ? .toRight : .toLeft
                    }
                }
                .onEnded { _ in
                    if abs(offset.width) > 100 {
                        let correct = offset.width > 0
                        removal?(correct)
                        if !correct {
                            // Same card is moved to the back; reset drag @State or it keeps near-zero opacity and huge offset.
                            offset = .zero
                            activeSwipeEdge = .none
                        }
                    } else {
                        offset = .zero
                    }
                }
        )
        .onChange(of: offset) { _, new in
            if isRestingOffset(new) {
                activeSwipeEdge = .none
            }
        }
        .onTapGesture {
            isShowingAnswer.toggle()
        }
        .animation(.bouncy, value: offset)
    }

    private func isRestingOffset(_ s: CGSize) -> Bool {
        abs(s.width) < 0.1 && abs(s.height) < 0.1
    }
}

#Preview {
    CardView(card: .example)
}
