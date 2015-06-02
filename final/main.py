from threaded import *

app = wx.App()
pathtracer = OpenGLApp(None, -1, 'Realtime GLSL pathtracer', size=(600, 480))
pathtracer.Show()
app.MainLoop()
