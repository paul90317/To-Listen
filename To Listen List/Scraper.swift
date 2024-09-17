//
//  Scraper.swift
//  To Listen List
//
//  Created by paul on 2024/9/17.
//

import AVKit
import Kanna

func fetchStreamURL(videoId: String) async throws -> String {
    guard let url = URL(string: "https://downloader.freemake.com/api/videoinfo/\(videoId)") else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.setValue("UA-18256617-1", forHTTPHeaderField: "x-analytics-header")

    let (data, _) = try await URLSession.shared.data(for: request)
    
    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
       let testId = json["videoId"] as? String,
       let qualities = json["qualities"] as? [[String: Any]],
       let lastQuality = qualities.last,
       let audioUrl = lastQuality["url"] as? String {
        if videoId == testId {
            return audioUrl
        }
    }
    throw URLError(.badServerResponse)
}

func fetchImage(videoId: String) async throws -> Data {
    let link = "https://i.ytimg.com/vi/\(videoId)/mqdefault.jpg"
    guard let url = URL(string: link) else {
        throw URLError(.badServerResponse)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

func fetchTitle(videoId: String) async throws -> String {
    let link = "https://www.youtube.com/watch?v=\(videoId)"
    guard let url = URL(string: link) else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.setValue("Mozilla/5.0 (compatible; curl/7.64.1)", forHTTPHeaderField: "User-Agent")

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let html = String(data: data, encoding: .utf8) else {
        throw URLError(.cannotDecodeContentData)
    }
    
    let xpath = "//meta[@name='title']"
    
    let doc = try Kanna.HTML(html: html, encoding: .utf8)
    
    guard let element = doc.xpath(xpath).first else {
        throw URLError(.cannotDecodeContentData)
    }
    
    guard let title = element["content"] else {
        throw URLError(.cannotDecodeContentData)
    }
    
    return title
}

func fetchAuthor(videoId: String) async throws -> String {
    let link = "https://www.youtube.com/watch?v=\(videoId)"
    guard let url = URL(string: link) else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.setValue("Mozilla/5.0 (compatible; curl/7.64.1)", forHTTPHeaderField: "User-Agent")

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let html = String(data: data, encoding: .utf8) else {
        throw URLError(.cannotDecodeContentData)
    }
    
    let xpath = "//link[@itemprop='name']"
    
    let doc = try Kanna.HTML(html: html, encoding: .utf8)
    
    guard let element = doc.xpath(xpath).first else {
        throw URLError(.cannotDecodeContentData)
    }
    
    guard let author = element["content"] else {
        throw URLError(.cannotDecodeContentData)
    }
    
    return author
}
