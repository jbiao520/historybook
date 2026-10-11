import Testing
@testable import HistorybookCore

@Test func firstArticleCanReturnHomeAndGoForwardAgain() {
    var model = ExplorationModel()
    model.open("chenqiao-mutiny")
    #expect(model.canGoBack)
    model.goBack()
    #expect(model.destination == .home)
    #expect(model.breadcrumbs.isEmpty)
    model.goForward()
    #expect(model.currentID == "chenqiao-mutiny")
    #expect(model.visitHistory == ["chenqiao-mutiny"])
}

@Test func sidebarPagesArePartOfBrowserNavigation() {
    var model = ExplorationModel()
    model.navigate(to: .search)
    model.open("chanyuan-treaty")
    model.navigate(to: .timeline)
    #expect(model.breadcrumbs.isEmpty)
    model.goBack()
    #expect(model.currentID == "chanyuan-treaty")
    model.goBack()
    #expect(model.destination == .search)
    model.goForward()
    #expect(model.currentID == "chanyuan-treaty")
    model.goForward()
    #expect(model.destination == .timeline)
}

@Test func breadcrumbJumpPreservesForwardPathAndRepeatedNodes() {
    var model = ExplorationModel()
    model.open("chenqiao-mutiny")
    model.open("zhao-kuangyin")
    model.open("chenqiao-mutiny")
    model.open("release-military-power")
    model.goToBreadcrumb(at: 0)
    #expect(model.breadcrumbs == ["chenqiao-mutiny"])
    model.goForward()
    #expect(model.currentID == "zhao-kuangyin")
    model.goForward()
    #expect(model.currentID == "chenqiao-mutiny")
    model.goForward()
    #expect(model.currentID == "release-military-power")
    #expect(model.visitHistory.count == 4)
    let unchanged = model
    model.goToBreadcrumb(at: -1)
    model.goToBreadcrumb(at: 99)
    #expect(model == unchanged)
}

@Test func trailDoesNotEnterVisitHistoryAndBackReturnsToIt() {
    var model = ExplorationModel()
    model.navigate(to: .topics)
    model.navigate(to: .trail("southern-defense"))
    model.open("wen-tianxiang")
    #expect(model.visitHistory == ["wen-tianxiang"])
    model.goBack()
    #expect(model.destination == .trail("southern-defense"))
    #expect(model.visitHistory == ["wen-tianxiang"])
    model.goForward()
    #expect(model.currentID == "wen-tianxiang")
    #expect(model.visitHistory == ["wen-tianxiang"])
}

@Test func newNavigationClearsForwardPathAndStartsNewArticleTrail() {
    var model = ExplorationModel()
    model.open("chenqiao-mutiny")
    model.open("zhao-kuangyin")
    model.goBack()
    model.navigate(to: .history)
    #expect(!model.canGoForward)
    model.open("chanyuan-treaty")
    #expect(model.breadcrumbs == ["chanyuan-treaty"])
    let unchanged = model
    model.open("chanyuan-treaty")
    #expect(model == unchanged)
}
