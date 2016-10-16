import CSDL2
import Basic

public func drawFilledRectangle(_ rectangle: Rect<Int>, color: Color) {
    var sdlRect = rectangle.asSDLRect()
    let sdlColor = SDL_MapRGB(targetSurface.pointee.format, color.red, color.green, color.blue)
    SDL_FillRect(targetSurface, &sdlRect, sdlColor)
}
