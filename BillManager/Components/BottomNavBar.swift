import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        (icon: "book.fill", label: "账单"),
        (icon: "chart.pie.fill", label: "统计"),
        (icon: "gearshape.fill", label: "设置")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                NavItem(
                    icon: tabs[index].icon,
                    label: tabs[index].label,
                    isSelected: selectedTab == index
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(Color.white.opacity(0.9))
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .colorMultiply(AppColors.backgroundAlt.opacity(0.5)),
            alignment: .top
        )
    }
}

struct NavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(height: 24)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 4, height: 4)
                    .scaleEffect(isSelected ? 1 : 0)
                    .opacity(isSelected ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BottomNavBar(selectedTab: .constant(0))
        .background(AppColors.background)
}