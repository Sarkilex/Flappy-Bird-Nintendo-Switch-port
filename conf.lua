function love.conf(t)
    t.window = t.window or {}
    t.window.width = 1280
    t.window.height = 720
    t.window.fullscreen = false
    t.window.vsync = 1

    t.identity = "flappy_bird_switch"
    t.version = "11.4"
    t.title = "Flappy Bird Switch"
    t.author = "Sarkilex"

    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = false
    t.modules.math = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = false
    t.modules.window = true
end