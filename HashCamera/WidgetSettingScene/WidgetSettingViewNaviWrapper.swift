//
//  WidgetSettingViewNaviWrapper.swift
//  HashCamera
//
//  Created by WG-Yang on 12/6/24.
//

import SwiftUI

///위젯 설정뷰 독립 실행시 사용
struct WidgetSettingViewNaviWrapper: View {
    // dismiss를 위한 환경 변수
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            WidgetSettingView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(uiImage: SystemUIImage.xmark.withRenderingMode(.alwaysTemplate))
                                .resizable()
                                .tint(.cyan)
                                .frame(width: 18, height: 18)
                            
                        }
                    }
                }
        }
    }
}

#Preview {
    WidgetSettingViewNaviWrapper()
}
