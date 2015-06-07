try:
    import wx
    from wx import glcanvas
except ImportError:
    raise ImportError, "Required dependency wx.glcanvas not present"

try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"

import time
from pathtracer import PathTracer
from utils import now
from mouse import Mouse
from tweaker import PathTracerTweaker


class OpenGLApp(wx.Frame):
    """ Single thread OpenGL application with wxPython """

    def __init__(self, parent, id, title, pos=wx.DefaultPosition,
        size=wx.DefaultSize, style=wx.DEFAULT_FRAME_STYLE, name='OpenGLApp'):

        wx.Frame.__init__(self, parent, id, title, pos, size, style, name)

        # Canvas attributes
        attribList = (glcanvas.WX_GL_RGBA,           # RGBA
                      glcanvas.WX_GL_DOUBLEBUFFER,   # Double Buffered
                      glcanvas.WX_GL_DEPTH_SIZE, 24) # 24 bit

        # Create the canvas
        self.canvas = glcanvas.GLCanvas(self, attribList=attribList)

        # Set the event handlers
        self.canvas.Bind(wx.EVT_ERASE_BACKGROUND, self.onEraseBackground)
        self.canvas.Bind(wx.EVT_SIZE, self.onResize)
        self.canvas.Bind(wx.EVT_PAINT, self.onPaint)
        self.canvas.Bind(wx.EVT_LEFT_DOWN, self.onMouseDown)
        self.canvas.Bind(wx.EVT_LEFT_UP, self.onMouseUp)
        self.canvas.Bind(wx.EVT_MOTION, self.onMouseMotion)
        self.canvas.Bind(wx.EVT_KEY_DOWN, self.onKeyDown)

        # Timer
        FRAME_ID = 0x42
        self._timer = wx.Timer(self.canvas, FRAME_ID)
        self.canvas.Bind(wx.EVT_TIMER, self.onFrame, id=FRAME_ID)
        fps = 60
        dt = 1000.0 / fps
        self._timer.Start(dt)

        # Mouse positions
        self.clickx = self.lastx = self.x = size[0] / 2.0
        self.clicky = self.lasty = self.y = size[1] / 2.0

        # Frame size
        self.size = size

        # PathTracer
        self._pathtracer = None

        # Pause rendering
        self.paused = False

        # PathTracer tweaker dialog
        self._tweaker = None
        #self._tweaker = PathTracerTweaker(self._parent, None, 'PathTracer params')

        # Give the focus to the canvsas
        self.canvas.SetFocus()


    ## Canvas Proxy Methods ##

    def getCanvasSize(self):
        """ Get the size of the OpenGL canvas """
        return self.canvas.GetClientSize()


    def swapBuffers(self):
        """ Swap the OpenGL buffers """
        self.canvas.SwapBuffers()


    ## wxPython Window Handlers ##

    def onEraseBackground(self, event):
        """ Process the erase background event """
        pass # Do nothing, to avoid flashing on MSWin


    def onResize(self, event):
        """ Process the resize event """

        size = self.getCanvasSize()

        # Keep ratio of mouse positions when resized
        self.x = self.x * size[0] / self.size[0]
        self.y = self.y * size[1] / self.size[1]
        self.lastx = self.lastx * size[0] / self.size[0]
        self.lasty = self.lasty * size[1] / self.size[1]
        self.clickx = self.clickx * size[0] / self.size[0]
        self.clicky = self.clicky * size[1] / self.size[1]

        self.size = size

        if self.canvas.GetContext():
            if self.pathtracer: self.pathtracer.resize(size)

        print "Resize: {}".format(size)

        event.Skip()


    def onPaint(self, event):
        """ Paint event handler used to perform initialization """
        # Activate the OpenGL context of the canvas
        self.canvas.SetCurrent()
        if self.pathtracer and not self.pathtracer.initialized:
            self.pathtracer.init(self.size)
        event.Skip()


    def onFrame(self, event):
        """ Generate a frame """
        if event.GetId() == self._timer.GetId():
            if not self.paused:
                mouse = Mouse(self.x, self.y, self.clickx, self.clicky)
                for iteration in self.pathtracer.render(mouse=mouse):
                    self.swapBuffers()


    def onMouseDown(self, event):
        """ Mouse button down handler """
        if not self.paused:
            self.canvas.CaptureMouse()
            self.x, self.y = event.GetPosition()
            self.y = self.size[1] - self.y # Invert y-axis
            self.lastx, self.lasty = self.x, self.y
            self.clickx, self.clicky = self.x, self.y


    def onMouseUp(self, event):
        """ Mouse button up handler """
        if not self.paused:
            self.canvas.ReleaseMouse()
            x, y = event.GetPosition()


    def onMouseMotion(self, event):
        """ Mouse moved handler """
        if not self.paused:
            if event.Dragging() and event.LeftIsDown():
                self.lastx, self.lasty = self.x, self.y
                self.x, self.y = event.GetPosition()
                self.y = self.size[1] - self.y # Invert y-axis
                self.canvas.Refresh(False)


    def onKeyDown(self, e):
        """ Key pressed handler """
        key = e.GetKeyCode()

        if key == wx.WXK_ESCAPE: # Close the app
            self._timer.Stop()
            self.Close()

        elif key == wx.WXK_SPACE:
            self.paused = not self.paused;
            print "{}".format("Pause" if self._paused else "Resume")

        elif key == ord('S'): # Toogle render stats printing
            self.pathracer.printStats = not self.pathtracer.printStats


    @property
    def pathtracer(self):
        """ Path tracer getter """
        return self._pathtracer

    @pathtracer.setter
    def pathtracer(self, p):
        """ Path tracer setter """
        self._pathtracer = p
        if self._tweaker:
            self._tweaker.pathtracer = p



# Main function
def pathtracing(size):
    app = wx.App()
    frame = OpenGLApp(None, -1, 'Relatime GLSL pathtracer (single thread)', size=size)
    frame.pathtracer = PathTracer()
    frame.Show()
    app.MainLoop()
