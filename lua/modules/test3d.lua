local bg = CreateCanvas { { Color.Hex("#202020") } }
return {
    title = "3D Bubble Testing",
    Draw = function (dt)
        RenderTest3D(resolution * 0.5, WEBCOLORS.BLUE, 100)
        RenderTest3D(resolution * 1.0, WEBCOLORS.RED, 50)
        RenderTest3D(Vector2(0, 0), WEBCOLORS.RED, 30)
        RenderTest3D(Vector2(100, 30), WEBCOLORS.RED, 30)
        RenderTest3D(Vector2(0, 0), WEBCOLORS.BLUE, 150)
        bg:draw()
    end,
}
