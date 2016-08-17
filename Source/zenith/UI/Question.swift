class Question<Result>: State {

    let gui: GraphicalUserInterface
    let title: String
    let resultHandler: (Result?) -> Void

    init(gui: GraphicalUserInterface, title: String, resultHandler: @escaping (Result?) -> Void) {
        self.gui = gui
        self.title = title
        self.resultHandler = resultHandler
    }
}
