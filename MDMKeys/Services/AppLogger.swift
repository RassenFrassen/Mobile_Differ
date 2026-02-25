import Foundation
import os.log

/// Centralized logging service that writes to both console and file
actor AppLogger {
    static let shared = AppLogger()
    
    private let logFileURL: URL
    private let maxLogFileSize: Int = 10 * 1024 * 1024 // 10 MB
    private let maxLogFiles: Int = 5
    private var fileHandle: FileHandle?
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    private init() {
        // Create logs directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("Differ", isDirectory: true)
        let logsDirectory = appDirectory.appendingPathComponent("Logs", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        // Create log file with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        self.logFileURL = logsDirectory.appendingPathComponent("differ-\(dateString).log")
        
        // Initialize file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        // Open file handle
        self.fileHandle = try? FileHandle(forWritingTo: logFileURL)
        self.fileHandle?.seekToEndOfFile()
        
        // Rotate old logs
        Task {
            await self.rotateLogsIfNeeded()
        }
    }
    
    /// Log a message with the specified level
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)\n"
        
        // Write to console using os_log
        let logger = Logger(subsystem: "com.differ.app", category: "general")
        logger.log(level: level.osLogType, "\(message)")
        
        // Write to file
        if let data = logMessage.data(using: .utf8) {
            fileHandle?.write(data)
        }
        
        // Check if rotation is needed
        Task {
            await rotateLogsIfNeeded()
        }
    }
    
    /// Convenience methods for different log levels
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, file: file, function: function, line: line)
    }
    
    /// Get the current log file URL
    func getCurrentLogFileURL() -> URL {
        logFileURL
    }
    
    /// Get all log files sorted by date (newest first)
    func getAllLogFiles() -> [URL] {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let logsDirectory = appSupport.appendingPathComponent("Differ/Logs", isDirectory: true)
        
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        return files.filter { $0.pathExtension == "log" }.sorted {
            let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    /// Read the contents of a log file
    func readLogFile(_ url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }
    
    /// Get log file size in bytes
    func getLogFileSize(_ url: URL) -> Int64? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64
    }
    
    /// Clear all log files
    func clearAllLogs() {
        fileHandle?.closeFile()
        fileHandle = nil
        
        let logFiles = getAllLogFiles()
        for file in logFiles {
            try? FileManager.default.removeItem(at: file)
        }
        
        // Recreate current log file
        FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        fileHandle?.seekToEndOfFile()
        
        info("All logs cleared")
    }
    
    /// Build a single combined log string (oldest to newest).
    func combinedLogContent() -> String {
        let logFiles = getAllLogFiles()
        guard !logFiles.isEmpty else { return "" }

        var combinedContent = ""
        for logFile in logFiles.reversed() { // Oldest to newest
            if let content = readLogFile(logFile) {
                combinedContent += "=== \(logFile.lastPathComponent) ===\n"
                combinedContent += content
                combinedContent += "\n\n"
            }
        }
        return combinedContent
    }

    /// Export logs to a specified URL
    func exportLogs(to destinationURL: URL) throws {
        let logFiles = getAllLogFiles()
        guard !logFiles.isEmpty else {
            throw NSError(domain: "AppLogger", code: 1, userInfo: [NSLocalizedDescriptionKey: "No log files to export"])
        }

        let combinedContent = combinedLogContent()
        try combinedContent.write(to: destinationURL, atomically: true, encoding: .utf8)
        info("Logs exported to \(destinationURL.path)")
    }
    
    /// Rotate logs if current file exceeds max size
    private func rotateLogsIfNeeded() {
        guard let fileSize = getLogFileSize(logFileURL), fileSize > maxLogFileSize else {
            return
        }
        
        // Close current file
        fileHandle?.closeFile()
        
        // Get all log files and delete oldest if we have too many
        var logFiles = getAllLogFiles()
        while logFiles.count >= maxLogFiles {
            if let oldest = logFiles.last {
                try? FileManager.default.removeItem(at: oldest)
                logFiles.removeLast()
            }
        }
        
        // Create new log file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let logsDirectory = appSupport.appendingPathComponent("Differ/Logs", isDirectory: true)
        let newLogFile = logsDirectory.appendingPathComponent("differ-\(dateString).log")
        
        FileManager.default.createFile(atPath: newLogFile.path, contents: nil)
        fileHandle = try? FileHandle(forWritingTo: newLogFile)
        fileHandle?.seekToEndOfFile()
    }
    
    deinit {
        fileHandle?.closeFile()
    }
}

// MARK: - Convenience Global Functions
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await AppLogger.shared.debug(message, file: file, function: function, line: line)
    }
}

func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await AppLogger.shared.info(message, file: file, function: function, line: line)
    }
}

func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await AppLogger.shared.warning(message, file: file, function: function, line: line)
    }
}

func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await AppLogger.shared.error(message, file: file, function: function, line: line)
    }
}

func logCritical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await AppLogger.shared.critical(message, file: file, function: function, line: line)
    }
}
