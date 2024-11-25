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
        return ["Documents", "Photos", "Music", "Videos"]
    }

    // App Group을 통해 폴더 데이터 가져오기
    private func fetchFolders() -> [String] {
        // 실제 앱 데이터 로드
        let defaults = UserDefaults(suiteName: "group.com.yourapp.identifier")
        return defaults?.stringArray(forKey: "FolderNames") ?? sampleFolders()
    }
}

// MARK: - FolderListWidgetView
struct FolderListWidgetView: View {
    let entry: FolderListEntry

    var body: some View {
        VStack {
            HStack {
                Text("HashCamera")
                Spacer()
            }
            Spacer(minLength: 16)
            GeometryReader { geometry in
                    HStack() {
                        ForEach(entry.folderList, id: \.self) { folderName in
                            VStack(spacing: 4) {
                                Image(systemName: "folder.fill") // 공통 폴더 아이콘
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: geometry.size.height / 3)
                                    .foregroundColor(.yellow)
                                
                                Text(folderName) // 폴더 이름
                                    .font(.caption)
                                    .lineLimit(2)
                            }
                            .padding(4)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .background(Color.orange.opacity(0.2))

            }
      
        }
        .applyContainerBackground()
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
            self.containerBackground(Color.gray.gradient, for: .widget)

        } else {
            ZStack {
                Color(.systemBackground) // iOS 15-16: 기본 배경
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
            folderList: ["Category01", "Category02", "Category03", "Meal Records"]
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
