//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

@MainActor
enum SettingsSearchEngine {
    private static let searchResultCacheCapacity = 32
    private static var cachedSearchResultsByQuery: [String: [SettingsSearchEntry]] = [:]
    private static var cachedSearchResultsOrder: [String] = []

    private struct IndexedSettingsSearchEntry {
        let entry: SettingsSearchEntry
        let normalizedSection: String
        let normalizedTitle: String
        let normalizedSubtitle: String
        let normalizedKeywords: [String]
        let normalizedCombinedValues: String
    }

    private static let indexedSettingsSearchStorage: [IndexedSettingsSearchEntry] = SettingsSearchCatalog.entries.map { entry in
        let normalizedSection = normalized(entry.section)
        let normalizedTitle = normalized(entry.title)
        let normalizedSubtitle = normalized(entry.subtitle)
        let normalizedKeywords = entry.keywords.map(normalized)
        let normalizedCombinedValues = ([normalizedTitle, normalizedSection, normalizedSubtitle] + normalizedKeywords)
            .joined(separator: " ")

        return IndexedSettingsSearchEntry(
            entry: entry,
            normalizedSection: normalizedSection,
            normalizedTitle: normalizedTitle,
            normalizedSubtitle: normalizedSubtitle,
            normalizedKeywords: normalizedKeywords,
            normalizedCombinedValues: normalizedCombinedValues
        )
    }

    private static let normalizedPaneSearchValuesByPane: [SettingsPane: String] = {
        let groupedEntries = Dictionary(grouping: SettingsSearchCatalog.entries, by: \.pane)

        return Dictionary(uniqueKeysWithValues: SettingsPane.defaultOrder.map { pane in
            let indexedFeatureValues = groupedEntries[pane]?.flatMap {
                [$0.section, $0.title, $0.subtitle] + $0.keywords
            } ?? []
            let combinedValues = [pane.title, pane.subtitle] + pane.searchKeywords + indexedFeatureValues
            let normalizedValues = combinedValues.map(normalized)
            return (pane, normalizedValues.joined(separator: " "))
        })
    }()

    static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: "[\\p{P}\\p{S}]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func hasActiveQuery(_ query: String) -> Bool {
        !normalized(query).isEmpty
    }

    static func filteredPanes(for query: String, paneOrder: [SettingsPane]) -> [SettingsPane] {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else {
            return paneOrder
        }

        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)
        let resultPanes = Set(searchResults(for: query, paneOrder: paneOrder).map(\.pane))

        return paneOrder.filter { pane in
            resultPanes.contains(pane) ||
                matchesSearchQuery(
                    normalizedQuery: normalizedQuery,
                    queryTokens: queryTokens,
                    combinedValues: normalizedPaneSearchValuesByPane[pane] ?? ""
                )
        }
    }

    static func searchResults(for query: String, paneOrder: [SettingsPane]) -> [SettingsSearchEntry] {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else {
            return []
        }

        if let cached = cachedSearchResults(for: normalizedQuery) {
            return cached
        }

        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)
        let paneOrderMap = Dictionary(
            uniqueKeysWithValues: paneOrder.enumerated().map { ($1, $0) }
        )

        let results = indexedSettingsSearchStorage
            .compactMap { indexedEntry -> (SettingsSearchEntry, Int)? in
                let score = searchScore(
                    for: indexedEntry,
                    normalizedQuery: normalizedQuery,
                    queryTokens: queryTokens
                )
                guard score > 0 else {
                    return nil
                }
                return (indexedEntry.entry, score)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 {
                    return lhs.1 > rhs.1
                }

                let lhsPaneOrder = paneOrderMap[lhs.0.pane] ?? .max
                let rhsPaneOrder = paneOrderMap[rhs.0.pane] ?? .max
                if lhsPaneOrder != rhsPaneOrder {
                    return lhsPaneOrder < rhsPaneOrder
                }

                return lhs.0.title.localizedCaseInsensitiveCompare(rhs.0.title) == .orderedAscending
            }
            .map(\.0)

        storeSearchResults(results, for: normalizedQuery)
        return results
    }

    private static func cachedSearchResults(for normalizedQuery: String) -> [SettingsSearchEntry]? {
        guard let cachedResults = cachedSearchResultsByQuery[normalizedQuery] else {
            return nil
        }

        if let index = cachedSearchResultsOrder.firstIndex(of: normalizedQuery) {
            cachedSearchResultsOrder.remove(at: index)
        }
        cachedSearchResultsOrder.append(normalizedQuery)
        return cachedResults
    }

    private static func storeSearchResults(_ results: [SettingsSearchEntry], for normalizedQuery: String) {
        cachedSearchResultsByQuery[normalizedQuery] = results

        if let index = cachedSearchResultsOrder.firstIndex(of: normalizedQuery) {
            cachedSearchResultsOrder.remove(at: index)
        }
        cachedSearchResultsOrder.append(normalizedQuery)

        while cachedSearchResultsOrder.count > searchResultCacheCapacity {
            let evictedQuery = cachedSearchResultsOrder.removeFirst()
            cachedSearchResultsByQuery.removeValue(forKey: evictedQuery)
        }
    }

    private static func searchScore(
        for indexedEntry: IndexedSettingsSearchEntry,
        normalizedQuery: String,
        queryTokens: [String]
    ) -> Int {
        let title = indexedEntry.normalizedTitle
        let section = indexedEntry.normalizedSection
        let subtitle = indexedEntry.normalizedSubtitle
        let keywords = indexedEntry.normalizedKeywords
        let combinedValues = indexedEntry.normalizedCombinedValues

        guard
            combinedValues.contains(normalizedQuery) ||
            queryTokens.allSatisfy({ combinedValues.contains($0) })
        else {
            return 0
        }

        var score = 0
        if title.contains(normalizedQuery) { score += 120 }
        if section.contains(normalizedQuery) { score += 85 }
        if subtitle.contains(normalizedQuery) { score += 70 }
        if keywords.contains(where: { $0.contains(normalizedQuery) }) { score += 95 }

        for token in queryTokens {
            if title.contains(token) { score += 16 }
            if section.contains(token) { score += 11 }
            if subtitle.contains(token) { score += 9 }
            if keywords.contains(where: { $0.contains(token) }) { score += 14 }
        }

        return max(score, 1)
    }

    private static func matchesSearchQuery(
        normalizedQuery: String,
        queryTokens: [String],
        combinedValues: String
    ) -> Bool {
        if combinedValues.contains(normalizedQuery) {
            return true
        }

        return queryTokens.allSatisfy { token in
            combinedValues.contains(token)
        }
    }
}
