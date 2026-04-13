//
//  TempoMap.swift
//  MIDIKitFileBrowser
//
//  Created by Sinan Karasu on 9/7/25.
//

import MIDIKitSMF

struct TempoMap {
    // If PPQ-based: ppq > 0 and segs populated.
    // If timecode-based: ppq == 0 and timecodeFPS/ticksPerFrame set.
    let ppq: Int
    private let timecodeFPS: Double?
    private let ticksPerFrame: Int?
    // (tick, usPerQuarterNote, cumulativeSecondsAtTick)
    private let segs: [(tick: Int, us: Int, sec: Double)]

    init(file: MIDIFile) {
        switch file.timeBase {
        case .musical(let tpq):
            let ppq_ = Int(tpq)
            self.ppq = ppq_
            self.timecodeFPS = nil
            self.ticksPerFrame = nil

            // collect tempo events from all tracks
            var abs = 0
            var events: [(tick: Int, us: Int)] = [(0, 500_000)] // default 120 BPM (500,000 µs per QN)
            for tr in file.tracks {
                abs = 0
                for e in tr.events {
                    abs &+= Int(e.delta.ticksValue(using: file.timeBase))
                    if case let .tempo(_, t) = e {
                        // MIDIKit exposes BPM via bpmEncoded; convert to microseconds per quarter note.
                        let bpm = max(t.bpmEncoded, 0.0001) // avoid divide-by-zero
                        let usPerQN = Int((60_000_000.0 / bpm).rounded())
                        events.append((abs, usPerQN))
                    }
                }
            }
            events.sort { $0.tick < $1.tick }

            // prefix sums of seconds at each segment start
            var sec = 0.0
            var prevTick = 0
            var prevUS = events[0].us
            var tmp: [(Int, Int, Double)] = [(0, prevUS, 0)]
            for (tick, us) in events.dropFirst() {
                sec += Double(tick - prevTick) * (Double(prevUS) / 1_000_000.0) / Double(ppq_)
                tmp.append((tick, us, sec))
                prevTick = tick; prevUS = us
            }
            self.segs = tmp

        case .timecode(let frameRate, let tpf):
            // timecode-based: constant seconds per tick = 1 / (fps * ticksPerFrame)
            self.ppq = 0
            self.segs = [(0, 500_000, 0)] // unused in timecode path, but keep a valid array
            self.ticksPerFrame = Int(tpf)
            self.timecodeFPS = TempoMap.fps(from: frameRate)
        }
    }

    func seconds(at tick: Int) -> Double {
        if ppq == 0 {
            // timecode-based
            guard let fps = timecodeFPS, let tpf = ticksPerFrame else { return 0 }
            return Double(tick) / (fps * Double(tpf))
        }

        // PPQ-based: binary search segment (rightmost <= tick)
        let i = rightmostIndexLE(in: segs, targetTick: tick)
        let s = segs[i]
        let dt = tick - s.tick
        return s.sec + Double(dt) * (Double(s.us) / 1_000_000.0) / Double(ppq)
    }

    // Helper: derive frames-per-second from MIDIKit frame rate enum.
    private static func fps(from rate: MIDIFile.FrameRate) -> Double {
        switch rate {
        case .fps24:       return 24.0
        case .fps25:       return 25.0
        case .fps29_97d:   return 30000.0 / 1001.0
        case .fps30:       return 30.0
        @unknown default:
            // Fallback if MIDIKit adds new cases
            return 30.0
        }
    }

    // Rightmost index with segs[idx].tick <= targetTick
    private func rightmostIndexLE(in arr: [(tick: Int, us: Int, sec: Double)], targetTick: Int) -> Int {
        var lo = 0
        var hi = arr.count - 1
        while lo <= hi {
            let mid = (lo + hi) >> 1
            if arr[mid].tick <= targetTick {
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return max(0, min(hi, arr.count - 1))
    }
}
