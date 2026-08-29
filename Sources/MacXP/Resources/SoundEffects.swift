import Foundation

public enum XPSound: String, CaseIterable, Identifiable {
    case startup = "startup"
    case shutdown = "shutdown"
    case logon = "logon"
    case logoff = "logoff"
    case navigation = "navigation"
    case error = "error"
    case exclamation = "exclamation"
    case ding = "ding"
    case asterisk = "asterisk"
    case recycle = "recycle"
    case balloon = "balloon"
    case hardwareInsert = "hardware_insert"
    case hardwareRemove = "hardware_remove"

    public static var recycleBin: XPSound { .recycle }

    public var id: String { rawValue }
}

public struct SoundEffects {
    public static func generateSoundData(for sound: XPSound) -> Data {
        if let bundleData = XPAssetProvider.loadSoundData(for: sound) {
            return bundleData
        }
        return XPSoundSynthesizer.generateWAV(for: sound)
    }
}

public struct XPSoundSynthesizer {

    public static func generateWAV(for sound: XPSound) -> Data {
        let sampleRate: Double = 44100.0
        let samples: [Int16]

        switch sound {
        case .startup:
            samples = generateStartupChime(sampleRate: sampleRate)
        case .shutdown:
            samples = generateShutdownChime(sampleRate: sampleRate)
        case .logon:
            samples = generateLogonChime(sampleRate: sampleRate)
        case .logoff:
            samples = generateLogoffChime(sampleRate: sampleRate)
        case .navigation:
            samples = generateNavigationClick(sampleRate: sampleRate)
        case .error:
            samples = generateErrorChord(sampleRate: sampleRate)
        case .exclamation:
            samples = generateExclamationDing(sampleRate: sampleRate)
        case .ding:
            samples = generateDingTone(sampleRate: sampleRate)
        case .asterisk:
            samples = generateAsteriskTone(sampleRate: sampleRate)
        case .recycle:
            samples = generateRecycleBinSwoosh(sampleRate: sampleRate)
        case .balloon:
            samples = generateBalloonPop(sampleRate: sampleRate)
        case .hardwareInsert:
            samples = generateHardwareInsertTone(sampleRate: sampleRate)
        case .hardwareRemove:
            samples = generateHardwareRemoveTone(sampleRate: sampleRate)
        }

        return createWAVData(from: samples, sampleRate: Int(sampleRate))
    }

    // MARK: - Waveform Generators

    private static func generateStartupChime(sampleRate: Double) -> [Int16] {
        let duration = 3.2
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)

        struct ChordSegment {
            let startTime: Double
            let duration: Double
            let frequencies: [Double]
        }

        let chords: [ChordSegment] = [
            ChordSegment(startTime: 0.0, duration: 1.5, frequencies: [155.56, 233.08, 311.13, 392.00]), // Eb, Bb, Eb, G
            ChordSegment(startTime: 0.6, duration: 1.6, frequencies: [207.65, 261.63, 311.13, 415.30]), // Ab, C, Eb, Ab
            ChordSegment(startTime: 1.2, duration: 1.6, frequencies: [233.08, 293.66, 349.23, 466.16]), // Bb, D, F, Bb
            ChordSegment(startTime: 1.8, duration: 1.4, frequencies: [311.13, 392.00, 466.16, 622.25])  // Eb, G, Bb, Eb
        ]

        for chord in chords {
            let startSample = Int(chord.startTime * sampleRate)
            let chordSampleCount = Int(chord.duration * sampleRate)
            let endSample = min(totalSamples, startSample + chordSampleCount)

            for i in startSample..<endSample {
                let t = Double(i - startSample) / sampleRate
                let progress = t / chord.duration
                // Attack & Decay Envelope
                let attack = min(1.0, t / 0.08)
                let decay = max(0.0, 1.0 - progress)
                let envelope = attack * pow(decay, 1.2)

                var sampleVal = 0.0
                for (idx, freq) in chord.frequencies.enumerated() {
                    let weight = 1.0 / Double(chord.frequencies.count)
                    let base = sin(2.0 * .pi * freq * t)
                    let harm1 = 0.35 * sin(2.0 * .pi * (freq * 2.0) * t)
                    let harm2 = 0.15 * sin(2.0 * .pi * (freq * 3.0) * t)
                    let sub = (idx == 0) ? 0.25 * sin(2.0 * .pi * (freq * 0.5) * t) : 0.0
                    sampleVal += (base + harm1 + harm2 + sub) * weight
                }
                buffer[i] += sampleVal * envelope * 0.55
            }
        }

        return normalizeAndConvert(buffer)
    }

    private static func generateShutdownChime(sampleRate: Double) -> [Int16] {
        let duration = 2.4
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)

        struct ChordSegment {
            let startTime: Double
            let duration: Double
            let frequencies: [Double]
        }

        let chords: [ChordSegment] = [
            ChordSegment(startTime: 0.0, duration: 0.9, frequencies: [415.30, 523.25, 622.25]), // G#4, C5, D#5
            ChordSegment(startTime: 0.5, duration: 0.9, frequencies: [311.13, 392.00, 466.16]), // D#4, G4, A#4
            ChordSegment(startTime: 1.0, duration: 0.9, frequencies: [207.65, 261.63, 311.13]), // G#3, C4, D#4
            ChordSegment(startTime: 1.4, duration: 1.0, frequencies: [155.56, 196.00, 233.08])  // D#3, G3, A#3
        ]

        for chord in chords {
            let startSample = Int(chord.startTime * sampleRate)
            let chordSampleCount = Int(chord.duration * sampleRate)
            let endSample = min(totalSamples, startSample + chordSampleCount)

            for i in startSample..<endSample {
                let t = Double(i - startSample) / sampleRate
                let progress = t / chord.duration
                let attack = min(1.0, t / 0.06)
                let decay = max(0.0, 1.0 - progress)
                let envelope = attack * pow(decay, 1.5)

                var sampleVal = 0.0
                for freq in chord.frequencies {
                    let base = sin(2.0 * .pi * freq * t)
                    let warmHarmonic = 0.25 * sin(2.0 * .pi * (freq * 2.0) * t)
                    sampleVal += (base + warmHarmonic) / Double(chord.frequencies.count)
                }
                buffer[i] += sampleVal * envelope * 0.6
            }
        }

        return normalizeAndConvert(buffer)
    }

    private static func generateNavigationClick(sampleRate: Double) -> [Int16] {
        let duration = 0.04
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let decay = exp(-t * 90.0)
            let freq = 1800.0 - (t / duration) * 1200.0
            let click = sin(2.0 * .pi * freq * t)
            buffer[i] = click * decay * 0.8
        }

        return normalizeAndConvert(buffer)
    }

    private static func generateErrorChord(sampleRate: Double) -> [Int16] {
        let duration = 0.8
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let freqs = [130.81, 196.00, 261.63, 329.63] // C3, G3, C4, E4

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let attack = min(1.0, t / 0.01)
            let decay = exp(-t * 4.5)
            let envelope = attack * decay

            var val = 0.0
            for freq in freqs {
                let base = sin(2.0 * .pi * freq * t)
                let brass = 0.3 * sin(2.0 * .pi * (freq * 2.0) * t)
                val += (base + brass) / Double(freqs.count)
            }
            buffer[i] = val * envelope * 0.75
        }

        return normalizeAndConvert(buffer)
    }

    private static func generateExclamationDing(sampleRate: Double) -> [Int16] {
        let duration = 0.85
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let baseFreq = 1046.50 // C6

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let attack = min(1.0, t / 0.005)
            let decay = exp(-t * 5.0)
            let envelope = attack * decay

            let fundamental = sin(2.0 * .pi * baseFreq * t)
            let chime1 = 0.4 * sin(2.0 * .pi * (baseFreq * 2.0) * t)
            let chime2 = 0.15 * sin(2.0 * .pi * (baseFreq * 3.01) * t)
            buffer[i] = (fundamental + chime1 + chime2) * envelope * 0.7
        }

        return normalizeAndConvert(buffer)
    }

    private static func generateLogonChime(sampleRate: Double) -> [Int16] {
        let duration = 1.6
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let freqs = [311.13, 392.00, 466.16, 622.25] // Eb4, G4, Bb4, Eb5

        for (idx, freq) in freqs.enumerated() {
            let offset = Double(idx) * 0.15
            let start = Int(offset * sampleRate)
            for i in start..<totalSamples {
                let t = Double(i - start) / sampleRate
                let env = min(1.0, t / 0.03) * exp(-t * 3.5)
                buffer[i] += sin(2.0 * .pi * freq * t) * env * 0.4
            }
        }
        return normalizeAndConvert(buffer)
    }

    private static func generateLogoffChime(sampleRate: Double) -> [Int16] {
        let duration = 1.6
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let freqs = [622.25, 466.16, 392.00, 311.13] // Eb5, Bb4, G4, Eb4

        for (idx, freq) in freqs.enumerated() {
            let offset = Double(idx) * 0.15
            let start = Int(offset * sampleRate)
            for i in start..<totalSamples {
                let t = Double(i - start) / sampleRate
                let env = min(1.0, t / 0.03) * exp(-t * 3.5)
                buffer[i] += sin(2.0 * .pi * freq * t) * env * 0.4
            }
        }
        return normalizeAndConvert(buffer)
    }

    private static func generateDingTone(sampleRate: Double) -> [Int16] {
        let duration = 0.5
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let freq = 1760.0 // A6

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let env = min(1.0, t / 0.002) * exp(-t * 7.0)
            buffer[i] = (sin(2.0 * .pi * freq * t) + 0.3 * sin(2.0 * .pi * freq * 2 * t)) * env * 0.7
        }
        return normalizeAndConvert(buffer)
    }

    private static func generateAsteriskTone(sampleRate: Double) -> [Int16] {
        let duration = 0.6
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let freqs = [523.25, 659.25, 783.99] // C5, E5, G5 major triad

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let env = min(1.0, t / 0.01) * exp(-t * 5.0)
            var val = 0.0
            for f in freqs {
                val += sin(2.0 * .pi * f * t)
            }
            buffer[i] = val * env * 0.35
        }
        return normalizeAndConvert(buffer)
    }

    private static func generateBalloonPop(sampleRate: Double) -> [Int16] {
        let duration = 0.3
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let f1 = 880.0
        let f2 = 1320.0

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let env = min(1.0, t / 0.008) * exp(-t * 12.0)
            let tone = (t < 0.1) ? sin(2.0 * .pi * f1 * t) : sin(2.0 * .pi * f2 * (t - 0.1))
            buffer[i] = tone * env * 0.75
        }
        return normalizeAndConvert(buffer)
    }

    private static func generateHardwareInsertTone(sampleRate: Double) -> [Int16] {
        let duration = 0.35
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let notes = [440.0, 554.37, 659.25] // A4, C#5, E5

        for (idx, freq) in notes.enumerated() {
            let offset = Double(idx) * 0.08
            let start = Int(offset * sampleRate)
            for i in start..<totalSamples {
                let t = Double(i - start) / sampleRate
                let env = min(1.0, t / 0.005) * exp(-t * 14.0)
                buffer[i] += sin(2.0 * .pi * freq * t) * env * 0.5
            }
        }
        return normalizeAndConvert(buffer)
    }

    private static func generateHardwareRemoveTone(sampleRate: Double) -> [Int16] {
        let duration = 0.35
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)
        let notes = [659.25, 554.37, 440.0] // E5, C#5, A4

        for (idx, freq) in notes.enumerated() {
            let offset = Double(idx) * 0.08
            let start = Int(offset * sampleRate)
            for i in start..<totalSamples {
                let t = Double(i - start) / sampleRate
                let env = min(1.0, t / 0.005) * exp(-t * 14.0)
                buffer[i] += sin(2.0 * .pi * freq * t) * env * 0.5
            }
        }
        return normalizeAndConvert(buffer)
    }

    private static func generateRecycleBinSwoosh(sampleRate: Double) -> [Int16] {
        let duration = 0.45
        let totalSamples = Int(sampleRate * duration)
        var buffer = [Double](repeating: 0.0, count: totalSamples)

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let envelope = sin(.pi * progress)
            let noise = Double.random(in: -1.0...1.0)
            let swooshFreq = 300.0 + 800.0 * (1.0 - progress)
            let tone = sin(2.0 * .pi * swooshFreq * t)
            buffer[i] = (noise * 0.4 + tone * 0.6) * envelope * 0.65
        }

        return normalizeAndConvert(buffer)
    }

    private static func normalizeAndConvert(_ buffer: [Double]) -> [Int16] {
        let maxVal = buffer.map { abs($0) }.max() ?? 1.0
        let scale = maxVal > 0.0 ? (30000.0 / maxVal) : 1.0

        return buffer.map { sample in
            let clamped = max(-32767.0, min(32767.0, sample * scale))
            return Int16(clamped)
        }
    }

    // MARK: - WAV Binary Header Creation

    private static func createWAVData(from samples: [Int16], sampleRate: Int) -> Data {
        var data = Data()
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate: UInt32 = UInt32(sampleRate) * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign: UInt16 = numChannels * (bitsPerSample / 8)
        let subchunk2Size: UInt32 = UInt32(samples.count * MemoryLayout<Int16>.size)
        let chunkSize: UInt32 = 36 + subchunk2Size

        // RIFF Header
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        data.append(chunkSize.littleEndianData)
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

        // "fmt " Subchunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        let subchunk1Size: UInt32 = 16
        data.append(subchunk1Size.littleEndianData)
        let audioFormat: UInt16 = 1 // PCM
        data.append(audioFormat.littleEndianData)
        data.append(numChannels.littleEndianData)
        data.append(UInt32(sampleRate).littleEndianData)
        data.append(byteRate.littleEndianData)
        data.append(blockAlign.littleEndianData)
        data.append(bitsPerSample.littleEndianData)

        // "data" Subchunk
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        data.append(subchunk2Size.littleEndianData)

        // PCM Sample Data
        samples.withUnsafeBufferPointer { bufferPtr in
            data.append(bufferPtr)
        }

        return data
    }
}

private extension UInt16 {
    var littleEndianData: Data {
        var val = self.littleEndian
        return Data(bytes: &val, count: MemoryLayout<UInt16>.size)
    }
}

private extension UInt32 {
    var littleEndianData: Data {
        var val = self.littleEndian
        return Data(bytes: &val, count: MemoryLayout<UInt32>.size)
    }
}
