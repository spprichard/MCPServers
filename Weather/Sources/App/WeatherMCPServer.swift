//
//  WeatherMCPServer.swift
//  Weather
//
//  Created by Steven Prichard on 2025-03-17.
//

import SwiftMCP
import Foundation

@MCPServer(name: "Weather", version: "0.0.1")
final class WeatherMCPServer: Sendable {
    let weatherClient = WeatherAPI()
    
    @MCPTool(description: "Priovides the current weather forcast for a provided latitde and longatude")
    func forecast(latitde: Double, longatude: Double) -> String {
        _forecast(latitde: latitde, longatude: longatude)
    }
    // MARK: At time of writing this, `@MCPTool` doesn't support calling `async` functions.
    // `_forecast` is meant to be a workaround which uses a Semaphore to block while we wait for the API call to return
    // not ideall...
    private func _forecast(latitde: Double, longatude: Double) -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?
        var taskError: Error?
        
        Task {
            do {
                result = try await weatherClient.getForecast(latitde: latitde, longatude: longatude)
            } catch {
                taskError = error
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = taskError {
            fputs("ERROR: \(error.localizedDescription)", stderr)
        }
        
        return result ?? "Unable to get forcast"
    }
}


struct WeatherAPI: Sendable {
    typealias ForecastURL = String
    typealias ForecastPeriods = [ForecastPeriod]
    private let baseURL = "api.weather.gov"
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init() {
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
    }
    
    func getForecast(latitde: Double, longatude: Double) async throws -> String {
        let forecastURL = try await getForecastURL(latitde: latitde, longatude: longatude)
        let forecastPeriods = try await fetchForcast(from: forecastURL)
        
        let stringifyedForecastPeriods = forecastPeriods
            .map(\.description)
            .joined(separator: "\n")
        
        return stringifyedForecastPeriods
    }

    
    private func getForecastURL(latitde: Double, longatude: Double) async throws(Errors) -> ForecastURL {
        guard let pointsURL = Endpoints.points(latitde: latitde, longatude: longatude).url() else {
            throw .invalidURL(.points)
        }
        
        do {
            let (data, _) = try await session.data(from: pointsURL)
            let result = try decoder.decode(PointsResult.self, from: data)
            return result.properties.forecast
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            throw .api(error, .points)
        }
    }
    
    private func fetchForcast(from url: ForecastURL) async throws(Errors) -> ForecastPeriods {
        guard let forecastURL = Endpoints.forecast(url).url() else {
            throw .invalidURL(.forecast)
        }
        
        do {
            let (data, _) = try await session.data(from: forecastURL)
            let result = try decoder.decode(ForecastResult.self, from: data)
            return result.properties.periods
        } catch {
            throw .api(error, .forecast)
        }
    }
}

extension WeatherAPI {
    enum Errors: Error {
        case invalidURL(ErrorDomain)
        case api(Error, ErrorDomain)
    }
    
    enum ErrorDomain {
        case forecast
        case points
    }
    
    enum Endpoints {
        case points(latitde: Double, longatude: Double)
        case forecast(String)
        
        func url() -> URL? {
            switch self {
            case .points(let latitde, let longatude):
                return URL(string: "https://api.weather.gov/points/\(latitde),\(longatude)")
            case .forecast(let urlString):
                return URL(string: urlString)
            }
        }
    }
    
    struct PointsResult: Codable {
        var properties: PointsProperties
    }
    
    struct PointsProperties: Codable {
        var forecast: String // Forecast URL
    }
    
    struct ForecastResult: Codable {
        var properties: ForecastProperties
    }
    
    struct ForecastProperties: Codable {
        var units: String
        var periods: [ForecastPeriod]
    }
    
    struct ForecastPeriod: Codable {
        var name: String
        var temperature: Int
        var temperatureUnit: String
        var windSpeed: String
        var windDirection: String
    }
}

extension WeatherAPI.ForecastPeriod: CustomStringConvertible {
    var description: String {
        """
        Forecast Period
        name: \(self.name)
        temperature: \(self.temperature) \(self.temperatureUnit)
        windSpeed: \(self.windSpeed) \(self.windDirection)
        ---
        """
    }
}
