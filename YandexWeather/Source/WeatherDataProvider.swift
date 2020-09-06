import Foundation

public protocol Location {
    var latitude: Double {get}
    var longitude: Double {get}
}

public struct WeatherResponse: Codable {
    public struct Fact: Codable {
        public let temp: Double
        public let feels_like: Double
        public let pressure_mm: Double
        public let humidity: Double
        public let condition: String
    }
    
    public let now: Int
    public let fact: Fact
}

open class WeatherDataProvider {
    private static let keyHeader = "X-Yandex-API-Key"
    private let key: String
    private var location: Location?
    private lazy var serviceUrl: URL = {
        return URL(string: "https://api.weather.yandex.ru/v2/forecast")!
    }()
    private lazy var client: URLSession = {
        let config = URLSessionConfiguration.default
        let client = URLSession(configuration: config)
        return client
    }()
    
    public init(key: String) {
        self.key = key
    }
    
    open func setLocation(_ location: Location) {
        self.location = location
    }
    
    open func getCurrentWeather(complete: @escaping (_ result: WeatherResponse?, _ error: String?) -> Void) {
        guard let location = location else {
            complete(nil, "Не указано положение")
            return
        }
        let url = URL(string: "?lat=" + String(location.latitude) + "&lon="  + String(location.longitude), relativeTo: serviceUrl)!
        var request = URLRequest(url: url)
        request.addValue(key, forHTTPHeaderField: WeatherDataProvider.keyHeader)
        client.dataTask(with: request, completionHandler: {data, _, error in
            if let error = error {
                complete(nil, "Ошибка выполнения запроса: " + error.localizedDescription)
                return
            }
            guard let data = data else {
                complete(nil, "Ошибка обработки ответа")
                return
            }
            
            do {
                let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
                complete(response, nil)
            } catch _ {
                complete(nil, "Ошибка обработки ответа")
                return
            }
        }).resume()
    }
}
