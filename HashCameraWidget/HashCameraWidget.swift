//
//  HashCameraWidget.swift
//  HashCameraWidget
//
//  Created by Anto-Yang on 11/24/24.
//

import WidgetKit
import SwiftUI

// MARK: - FolderListEntry
struct FolderListEntry: TimelineEntry {
    let date: Date
    let folderList: [String] // 폴더 이름 리스트
}

// MARK: - FolderListProvider
struct FolderListProvider: TimelineProvider {
    func placeholder(in context: Context) -> FolderListEntry {
        FolderListEntry(date: Date(), folderList: sampleFolders())
    }

    func getSnapshot(in context: Context, completion: @escaping (FolderListEntry) -> Void) {
        let entry = FolderListEntry(date: Date(), folderList: fetchFolders())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FolderListEntry>) -> Void) {
        let entry = FolderListEntry(date: Date(), folderList: fetchFolders())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    // 샘플 데이터 생성
    private func sampleFolders() -> [String] {
        return  ["Documents", "Diets", "Work Photos"]
    }

    // App Group을 통해 폴더 데이터 가져오기
    private func fetchFolders() -> [String] {
        // 실제 앱 데이터 로드
        return WidgetSetting.folderList.map { $0.name }
    }
}

// MARK: - FolderListWidgetView
struct FolderListWidgetView: View {
    let entry: FolderListEntry

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text("HashCamera")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                         LinearGradient(
                             gradient: Gradient(colors: [Color.majorLight,Color.majorDark]),
                             startPoint: .top,
                             endPoint: .bottom
                         )
                     )
                Spacer()
                HStack(spacing: 4) {
                    Link(destination: URL(string: "hashcamera://widget_select_camera")!) {
                        Button {
                            
                        } label: {
                            Image(systemName: "camera")
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                    
                    Link(destination: URL(string: "hashcamera://widget_select_settings")!) {
                       Button {
                           
                       } label: {
                           Image(systemName: "gearshape")
                       }
                       .buttonStyle(.bordered)
                       .buttonBorderShape(.capsule)
                   }

                }

            }
            
            VStack {
                ForEach(0..<2) { rowIndex in
                    HStack {
                        ForEach(0..<2) { columnIndex in
                            let index = rowIndex * 2 + columnIndex
                            if index < entry.folderList.count {
                                // Link로 감싸기
                                folderItemButton(for: entry.folderList[index], index: index)
                            } else {
                                addFolderButton()
                            }
                        }
                    }
                }
            }
      
        }
        .applyContainerBackground()
    }
    
    func addFolderButton() -> some View {
        return Link(destination: URL(string: "hashcamera://widget_add_folder")!) {
            Button {
                
            } label: {
                HStack {
                    Spacer(minLength: 0.0)
                    Image(systemName: "plus")
                    Spacer(minLength: 0.0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
          
        }
    }
    
    func folderItemButton(for folderName: String, index: Int) -> some View {
        // URL 설정 (링크 방식으로만 동작 가능)
        let url = URL(string: "hashcamera://widget_select_folder/\(index)")! // 특정 폴더의 고유 URL
        
        return Link(destination: url) {
            Button {
                
            } label: {
                HStack(spacing:4) {
                    Image(systemName: "camera.fill")
                    Text(folderName)
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0.0)
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
    }
    


    
}


struct HashCameraWidget: Widget {
    let kind: String = "HashCameraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FolderListProvider()) { entry in
            FolderListWidgetView(entry: entry)
        }
        .supportedFamilies([.systemMedium]) // 지원하는 크기
    }
}

// MARK: - Conditional Container Background
extension View {
    @ViewBuilder
    func applyContainerBackground() -> some View {
        if #available(iOS 17, *) {
            self.containerBackground(Color.widgetBackground, for: .widget)

        } else {
            ZStack {
                Color.widgetBackground // iOS 15-16: 기본 배경
                self
            }
        }
    }
}

// MARK: - Widget Preview (iOS 15+ Compatibility)
struct FolderListWidget_Previews: PreviewProvider {
    static var previews: some View {
        FolderListWidgetView(entry: FolderListEntry(
            date: Date(),
            folderList: ["Documents", "Photos", "Buisness Photos"]//, "Meal Records"]
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
