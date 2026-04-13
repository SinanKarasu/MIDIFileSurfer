//
//  Logger+Extension.swift
//  SiKMIDIPlayer
//
//  Created by Sinan Karasu on 11/8/21.
//

import Foundation
import os.log


extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like viewDidLoad.
	static let viewLogger = os.Logger(subsystem: subsystem, category: "viewLogger")
	//static let viewCycle = Logger(subsystem: subsystem, category: "viewcycle")

}
