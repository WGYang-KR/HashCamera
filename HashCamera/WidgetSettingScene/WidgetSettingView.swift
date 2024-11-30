//
//  WidgetSettingView.swift
//  HashCamera
//
//  Created by Anto-Yang on 11/30/24.
//

import SwiftUI
import WidgetKit

struct WidgetSettingView: View {
    @StateObject private var vm = WidgetSettingVM()
    
    // 선택된 아이템을 저장하는 배열
    @State private var selectedItems: [String] = []
    
    var body: some View {
        
        GeometryReader { geometry in
            
            VStack {
                
                Rectangle()
                    .foregroundStyle(Color.cyan.opacity(0.2))
                //                    .frame(width: 350, height: 150)
                    .frame(height:geometry.size.height/4)
                    .overlay {
                        FolderListWidgetView(entry: FolderListEntry(
                            date: Date(),
                            folderList: vm.selectedItems.map({$0.name})
                        ))
                        .padding(16)
                    }
                    .cornerRadius(16)
                    .padding(16)
                List {
                    Section(header: Spacer(minLength: 0)) {
                        
                        ForEach(vm.folders, id: \.self) { item in
                            HStack {
                                Text(item.name)
                                
                                Spacer()
                                
                                // 선택된 아이템일 경우 별표 표시
                                if vm.selectedItems.contains(item) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 16))
                                }
                            }
                            .contentShape(Rectangle()) // 전체 영역 클릭 가능
                            .onTapGesture {
                                vm.toggleSelection(for: item)
                            }
                        }
                    }
                   
                }
                .listStyle(.insetGrouped)
                .environment(\.defaultMinListHeaderHeight, 0)
                .onAppear {
#if DEBUG
                    vm.initSampleData()
#else
                    vm.initFolders()
#endif
                }
            }
        }
    }
}

#Preview {
    WidgetSettingView()
}
