//
//  SoundManager.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-13.
//

import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    var audioPlayer: AVAudioPlayer?

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    /// Plays a sound based on the scan result type.
    /// - Parameter type: The type of scan result, either success or failure.
    func playSound(type: ScanResultType) {
        let soundFileName: String
        switch type {
        case .success:
            soundFileName = "successTone"
        case .failure:
            soundFileName = "failureTone"
        case .technical:
            soundFileName = "attentionTone"
        }
        
        guard let path = Bundle.main.path(forResource: soundFileName, ofType: "mp3") else {
            print("Sound file not found.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            print("Could not load sound file: \(error)")
        }
    }
}
