import AppMetricaCore

final class AnalyticsService {
    static func activate() {
        guard
            let configuration = AppMetricaConfiguration(apiKey: "10f0e226-616c-443c-adf1-d84568c4de83")
        else { return }
        AppMetrica.activate(with: configuration)
    }
    
    func report(event: String, params : [AnyHashable : Any]) {
        AppMetrica.reportEvent(name: event, parameters: params, onFailure: { error in
            print("REPORT ERROR: %@", error.localizedDescription)
        })
    }
}
