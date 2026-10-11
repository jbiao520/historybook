import HistorybookCore
import SwiftUI
import WebKit

struct ArticleWebView: NSViewRepresentable {
    var html: String
    var baseURL: URL
    var onOpenNode: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onOpenNode: onOpenNode)
    }

    func makeNSView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.load(html: html, baseURL: baseURL, into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onOpenNode = onOpenNode
        context.coordinator.load(html: html, baseURL: baseURL, into: webView)
    }

    @MainActor
    final class Coordinator: NSObject {
        var onOpenNode: (String) -> Void
        private var lastHTML: String?

        init(onOpenNode: @escaping (String) -> Void) {
            self.onOpenNode = onOpenNode
        }

        func load(html: String, baseURL: URL, into webView: WKWebView) {
            guard html != lastHTML else { return }
            lastHTML = html
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }
}

extension ArticleWebView.Coordinator: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if let id = HistoryLink.nodeID(from: url) {
            onOpenNode(id)
            decisionHandler(.cancel)
            return
        }
        if url.scheme == "http" || url.scheme == "https" {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
