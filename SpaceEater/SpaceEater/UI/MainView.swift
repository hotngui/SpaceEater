//
// Created by Joey Jarosz on 5/24/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @AppStorage("numberOfFiles") var numberOfFilesUD = FileGenerator.defaultNumberOfFiles
    @AppStorage("sizeOfFilesInBytes") var sizeOfFilesInBytesUD = FileGenerator.defaultSizeOfFileInBytes

    @State private var numberOfFiles: Int = FileGenerator.defaultNumberOfFiles
    @State private var sizeOfFilesInBytes: Double = FileGenerator.defaultSizeOfFileInBytes

    @State private var dummyRefresher = false
    @State private var isGeneratingFiles = false
    @State private var isDeletingFiles = false
    @State private var isBusy = false
    @State private var isShowingError = false
    @State private var errorMessage: String?

    private let generator = FileGenerator()
    
    private let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 3
        formatter.numberFormatter.minimumFractionDigits = 3
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Files") {
                    Stepper("File Size: \(convert(sizeOfFilesInBytes, from: .bytes, to: .megabytes).formatted())",
                            onIncrement: { incrementFileSizeValue() },
                            onDecrement: { decrementFileSizeValue() })

                    Stepper("Number Of Files: \(numberOfFiles)",
                            value: $numberOfFiles,
                            in: 1...100,
                            step: FileGenerator.defaultNumberOfFiles)

                    HStack {
                        deleteOneFileButton()
                        Spacer()
                        deleteAllFilesButton()
                        Spacer()
                        generateFilesButton()
                    }
                }
                
                Section {
                    HStack {
                        Text("Size:")
                        Spacer()
                        Text("\(formatter.string(from: convert(generator.usedDisk(), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                } header : {
                    Text("Eaten")
                        .padding(.top, -12)
                }

                Section {
                    HStack {
                        Text("Total:")
                        Spacer()
                        Text("\(formatter.string(from: convert(Double(UIDevice.current.totalDiskSpaceInBytes), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                    HStack {
                        Text("Used:")
                        Spacer()
                        Text("\(formatter.string(from: convert(Double(UIDevice.current.usedDiskSpaceInBytes), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                } header : {
                    Text("Device Disk Space")
                        .padding(.top, -12)
                }

                Section {
                    HStack {
                        Text("For Usage:")
                        Spacer()
                        Text("\(formatter.string(from: convert(Double(UIDevice.current.availableCapacityInBytes), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                    HStack {
                        Text("For Important Usage:")
                        Spacer()
                        Text("\(formatter.string(from: convert(Double(UIDevice.current.availableCapacityForImportantUsage), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                    HStack {
                        Text("For Opportunistic Usage:")
                        Spacer()
                        Text("\(formatter.string(from: convert(Double(UIDevice.current.availableCapacityForOpportunisticUsage), from: .bytes, to: .gigabytes)))")
                            .monospaced()
                    }
                } header : {
                    Text("Device Available Capacity")
                        .padding(.top, -12)
                }
            }
            .navigationTitle("Spacer Eater")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isBusy)
            .overlay {
                if isBusy {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.accentColor)
                }
            }
            .id(dummyRefresher)
            
            // Useful pull-to-refresh if you expect disk space to be consumed by another app running in the background
            .refreshable {
                dummyRefresher.toggle()
            }
            
            // Useful when going back-and-forth between apps..
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    dummyRefresher.toggle()
                }
            }
            
            // When we use the initializer variant of the `Stepper` view that we are using we run into issues
            // when we try to read/write from `AppStorage` directly so we set/get them as seperate points in time...
            .onAppear {
                sizeOfFilesInBytes = sizeOfFilesInBytesUD
                numberOfFiles = numberOfFilesUD
            }
            .onChange(of: sizeOfFilesInBytes) { value in
                sizeOfFilesInBytesUD = value
            }
            .onChange(of: numberOfFiles) { value in
                numberOfFilesUD = value
            }
        }
    }
    
    @ViewBuilder
    private func deleteOneFileButton() -> some View {
        Button("Delete One File", role: .destructive) {
            isBusy.toggle()
            
            Task {
                try! await generator.removeFiles(1)
                isBusy.toggle()
            }
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private func deleteAllFilesButton() -> some View {
        Button("Delete All Files", role: .destructive) {
            isDeletingFiles.toggle()
        }
        .buttonStyle(.borderedProminent)
        .alert("Delete All Files", isPresented: $isDeletingFiles) {
            Button("DELETE", role: .destructive) {
                isBusy.toggle()
                
                Task {
                    try! await generator.removeFiles()
                    isBusy.toggle()
                }
            }
        } message: {
            Text("Do you really want to delete all the files created by this tool?")
        }
    }

    @ViewBuilder
    private func generateFilesButton() -> some View {
        Button("Generate Files", role: .none) {
            isGeneratingFiles.toggle()
            isBusy.toggle()
            
            Task {
                do {
                    try await generator.generate(numberOfFiles: numberOfFiles, sizeOfFilesInBytes: sizeOfFilesInBytes)
                    isGeneratingFiles.toggle()
                    isBusy.toggle()
                } catch {
                    errorMessage = error.localizedDescription
                    isBusy.toggle()
                    isGeneratingFiles.toggle()
                    isShowingError.toggle()
                }
            }
            
        }
        .buttonStyle(.borderedProminent)
        .alert(isPresented: $isShowingError) {
            Alert(
                title: Text("File Generation"),
                message: Text("\(errorMessage ?? "")")
            )
        }
    }

    // MARK - Stepper Support
    
    /// Increments the size of the files to be generated. The effective `step` value changes such that when the value is less than 100 it steps by 10, otherwise it steps by 100.
    /// This makes the range 10-100 by 10, 200-1000 by 100
    ///
    private func incrementFileSizeValue() {
        if sizeOfFilesInBytes >= (FileGenerator.defaultSizeOfFileInBytes * 10) {
            return
        }
        if sizeOfFilesInBytes >= FileGenerator.defaultSizeOfFileInBytes {
            sizeOfFilesInBytes += FileGenerator.defaultSizeOfFileInBytes
        } else {
            sizeOfFilesInBytes += FileGenerator.defaultSizeOfFileInBytes / 10
        }
    }
    
    /// Decrements the size of the files to be generated. The effective `step` value changes such that when the value is less than 100 it steps by 10, otherwise it steps by 100.
    /// This makes the range 10-100 by 10, 200-1000 by 100
    ///
    private func decrementFileSizeValue() {
        if sizeOfFilesInBytes <=  (FileGenerator.defaultSizeOfFileInBytes / 10) {
            return
        }
        if sizeOfFilesInBytes <= FileGenerator.defaultSizeOfFileInBytes {
            sizeOfFilesInBytes -= FileGenerator.defaultSizeOfFileInBytes / 10
        } else {
            sizeOfFilesInBytes -= FileGenerator.defaultSizeOfFileInBytes
        }
    }
    
    // MARK - Utilities
    
    private func convert(_ value: Double, from inUnit: UnitInformationStorage, to outUnit: UnitInformationStorage) -> Measurement<UnitInformationStorage> {
        return Measurement<UnitInformationStorage>(value: value, unit: inUnit).converted(to: outUnit)
    }
}

#Preview {
    MainView()
}
