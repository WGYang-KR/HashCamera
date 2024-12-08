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
                
                VStack(spacing:0.0) {
                    
                    Text(localizedString(forKey: "N012_4", value: "Home Screen Widget Preview"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 8)
                    
                    Rectangle()
                        .foregroundStyle(Color.cyan.opacity(0.2))
                        .frame(height:geometry.size.height/4)
                        .overlay {
                            FolderListWidgetView(entry: FolderListEntry(
                                date: Date(),
                                folderList: vm.selectedItems.map({$0.name})
                            ))
                            .padding(16)
                        }
                        .cornerRadius(16)
                        .padding(.horizontal, 20).padding(.bottom, 8)
                        
                    Divider()
                        .padding(.vertical, 8)
                    

                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizedString(forKey: "N012_2", value: "Folder List"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(localizedString(forKey: "N012_3", value: "Select the folder to display on the widget."))
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                  
              
                    List {
                        Section(header: Spacer(minLength: 0)) {
                            
                            ForEach(vm.folders, id: \.self) { item in
                                HStack {
                                    Image(systemName:"folder")
                                        .foregroundColor(.cyan)
                                        .font(.system(size: 16))
                                    Text(item.name)
                                    
                                    Spacer()
                                    
                                    // 선택된 아이템일 경우 별표 표시
                                    if vm.selectedItems.contains(item) {
                                        Image(systemName:"checkmark")
                                            .foregroundColor(.blue)
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
                        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                            vm.initSampleData()
                        } else {
                            vm.initVM()
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemBackground))
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FolderCRUDAlert().beginCreateAlertSWiftUI()
                    } label: {
                        Image(uiImage: SystemUIImage.folderBadgePlus.withRenderingMode(.alwaysTemplate))
                            .resizable()
                            .scaledToFit()
                            .tint(.cyan)
                            .frame(height: 20)
                    }
                }
            })
            .navigationBarTitle(localizedString(forKey: "N012_1", value: "Widget Setting"), displayMode: .inline)
    }

}

#Preview {
    WidgetSettingView()
}
