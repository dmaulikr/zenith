import CSDL2

public func drawRectangle(_ rectangle: Rect<Int>, color: Color, filled: Bool,
                          blendMode: SDL_BlendMode = SDL_BLENDMODE_NONE) {
    SDL_SetRenderDrawColor(renderer, color.red, color.green, color.blue, color.alpha)
    SDL_SetRenderDrawBlendMode(renderer, blendMode)
    var sdlRect = rectangle.asSDLRect()
    if filled {
        SDL_RenderFillRect(renderer, &sdlRect)
    } else {
        SDL_RenderDrawRect(renderer, &sdlRect)
    }
}
