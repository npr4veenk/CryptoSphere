import SwiftUI
import AudioToolbox

struct KeyPadValue {
    
    var stringValue: String = ""
    var stackViews: [Number] = []
    
    struct Number: Identifiable, Equatable {
        var id: String = UUID().uuidString
        var value: String = ""
        var isComma: Bool = false
        var commaID: Int = 0
    }
    
    mutating func append(_ number: Int) {
        guard !isExceedingMaxLength, (number == 0 ? !stringValue.isEmpty : true) else { return }
        
        stringValue.append(String(number))
        stackViews.append(.init(value: String(number)))
        
        updateCommas()
    }
    
    mutating func removeLast() {
        guard !stringValue.isEmpty else { return }
        
        stringValue.removeLast()
        stackViews.removeLast()
        
        updateCommas()
    }
    
    mutating func handleDecimalPoint() {
        guard !stringValue.contains(".") && !isExceedingMaxLength else { return }
        
        if stringValue.isEmpty {
            stringValue = "0."
        } else {
            stringValue.append(".")
        }
        
        stackViews.append(.init(value: "."))
    }
    
    mutating func updateCommas() {
        guard !stringValue.isEmpty else {
            stackViews.removeAll()
            return
        }
        
        let components = stringValue.split(separator: ".", omittingEmptySubsequences: false)
        let digits = Array(components[0])
        var formattedString = ""
        var commaCounter = 0
        
        for i in stride(from: digits.count - 1, through: 0, by: -1) {
            formattedString.insert(digits[i], at: formattedString.startIndex)
            commaCounter += 1
            if commaCounter == 3 && i != 0 {
                formattedString.insert(",", at: formattedString.startIndex)
                commaCounter = 0
            }
        }
        
        if components.count > 1 {
            formattedString.append(".\(components[1])")
        }
        
        stackViews = formattedString.enumerated().map { (index, char) in
            Number(value: String(char), isComma: char == ",", commaID: index)
        }
    }
    
    var isEmpty: Bool {
        stringValue.isEmpty
    }
    
    var isExceedingMaxLength: Bool {
        let numbersOnly = stringValue.replacingOccurrences(of: ".", with: "")
        return numbersOnly.count >= 13
    }
}

struct TextFieldInput: View {
    
    @Binding var selectedOption: String
    let coinImage: String
    @Binding var value: KeyPadValue
    let mot: String 
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 60){
            AnimatedTextView()
                .frame(height: 50)
                .fontDesign(.rounded)
            // Reset the value when switching to Buy in USD
                .onChange(of: selectedOption) {
                    value.stringValue = ""
                    value.stackViews = []
                }
            
            CustomKeypad()
                .fontDesign(.rounded)
        }
    }
    
    @ViewBuilder
    func AnimatedTextView() -> some View {
        let length = value.stringValue.count
        let fontSize: CGFloat = length <= 6 ? 40 : length <= 11 ? 35 : length <= 13 ? 30 : 28

        HStack(spacing: 2) {
            if mot == "Buy" && selectedOption != "Buy in Units" {
                Text("$")
                    .padding(.trailing, 5)
                    .font(.system(size: fontSize, weight: .bold))
            }

            if value.isEmpty {
                Text("0")
                    .font(.system(size: fontSize, weight: .black))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                ForEach(Array(value.stackViews.enumerated()), id: \.element.id) { index, number in
                    Group {
                        if number.isComma {
                            Text(",")
                                .matchedGeometryEffect(id: number.commaID, in: animation)
                        } else {
                            Text(number.value)
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        }
                    }
                    .font(.system(size: fontSize, weight: .black))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3), value: value.stackViews)
                }
            }
        }
        .font(.system(size: fontSize, weight: .bold, design: .rounded))
    }

    
    @ViewBuilder
    func CustomKeypad() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 3)){
            ForEach(1...9, id: \.self){ index in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3)) {
                        value.append(index)
                    }
                    AudioServicesPlaySystemSound(1519)
                } label: {
                    Text("\(index)")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 65)
                        .contentShape(Rectangle())
                }
            }
            
            ForEach([".", "0", "delete.left.fill"], id: \.self) { string in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3)) {
                        if string == "0" {
                            value.append(0)
                        } else if string == "delete.left.fill" {
                            value.removeLast()
                            AudioServicesPlaySystemSound(1579)
                        } else if string == "." {
                            value.handleDecimalPoint()
                        }
                    }
                } label: {
                    Group {
                        if string == "delete.left.fill" {
                            Image(systemName: string)
                        } else {
                            Text(string)
                        }
                    }
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 65)
                    .contentShape(Rectangle())
                }
                .buttonRepeatBehavior(string != "delete.left.fill" ? .disabled : .enabled)
            }
        }
        .buttonStyle(KeypadButtonStyle())
    }
}

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(.primaryTheme)
                    .opacity(configuration.isPressed ? 1 : 0)
                    .padding(.horizontal, 5)
            }
            .animation(.easeInOut(duration: 0.50), value: configuration.isPressed)
    }
}

#Preview {
    BuySellView(
        mot: "Buy",
        coinSymbol: "btcusdt"
    )
}
