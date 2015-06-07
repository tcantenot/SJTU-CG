try:
    import wx
    from wx import glcanvas
except ImportError:
    raise ImportError, "Required dependency wx.glcanvas not present"

try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"

import time, threading
from command import CommandWorker, CommandQueue
from mouse import Mouse
from pathtracer import PathTracer
from tweaker import PathTracerTweaker


################################################################################

# Frame event
EVT_FRAME_TYPE = wx.NewEventType()
EVT_FRAME = wx.PyEventBinder(EVT_FRAME_TYPE, 1)

class FrameEvent(wx.PyCommandEvent):
    """ Event to signal that a frame has been rendered """

    def __init__(self, etype, eid, number):
        """Creates the event object"""
        wx.PyCommandEvent.__init__(self, etype, eid)
        self.number = number


################################################################################


class RenderThread(threading.Thread):
    """ Rendering thread """

    def __init__(self, parent):

        threading.Thread.__init__(self)

        # OpenGLApp parent
        self._parent = parent

        # wx.GLContext
        self._glcontext = None

        # PathTracer
        self._pathtracer = None

        # Queue containing the commands sent by the main app
        self._commandQueue = CommandQueue()

        # Is the rendering thread paused?
        self._paused = False

        # Should the rendering thread stop?
        self._stop = False


    def run(self):
        """ Run the rendering thread (called by RenderThread.start()) """

        # Create a thread local GL context and set it to the main app's canvas
        self._glcontext = glcanvas.GLContext(self._parent.canvas)
        self._glcontext.SetCurrent(self._parent.canvas)

        # Create the pathtracer
        self.pathtracer = PathTracer()
        self.pathtracer.init(self._parent.size)

        # Infinite rendering loop
        while True:

            # Process commands sent by the main app
            self._processCommands()

            if self._stop: break

            # Render a frame and post a frame event
            if not self._paused:
                mouse = self._parent.getMouse()
                for iteration in self.pathtracer.render(mouse=mouse):
                    frame = FrameEvent(EVT_FRAME_TYPE, -1, iteration)
                    wx.PostEvent(self._parent, frame)


    def resize(self, size):
        """ Resize the pathtracer """
        if self.pathtracer: self.pathtracer.resize(size)
        print "Resize: {}".format(size)


    def pause(self):
        """ Pause/Resume the rendering thread """
        self._paused = not self._paused
        print "{}".format("Pause" if self._paused else "Resume")


    def stop(self):
        """ Stop the rendering thread """
        self._stop = True

    def toogleStats(self):
        """ Toogle the print of the render stats """
        self.pathtracer.printStats = not self.pathtracer.printStats

    def sendCommand(self, func, args=[], kwargs={}):
        """ Send a command to the rendering thread """
        self._commandQueue.enqueue(func, args, kwargs)


    @property
    def pathtracer(self):
        """ Path tracer getter """
        return self._pathtracer


    @pathtracer.setter
    def pathtracer(self, p):
        """ Path tracer setter """
        self._pathtracer = p


    def _processCommands(self):
        """ Process the queued commands """
        if not self._commandQueue.empty():
            worker = CommandWorker(self._commandQueue)
            worker.run()


################################################################################

class OpenGLApp(wx.Frame):
    """ Multithread OpenGL application with wxPython """

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

        # Frame event produced by the rendering thread
        self.Bind(EVT_FRAME, self.onFrame)

        # Close event
        self.Bind(wx.EVT_CLOSE, self.onClose)

        # Mouse positions
        self.clickx = self.lastx = self.x = size[0] / 2.0
        self.clicky = self.lasty = self.y = size[1] / 2.0

        # App size
        self.size = size

        # Rendering thread
        self.renderThread = RenderThread(self)

        # Has the OpenGLApp been initialized?
        self.initialized = False

        # Paused?
        self.paused = False

        # PathTracer tweaker dialog
        self._tweaker = None

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

        # Send resize command to the rendering thread
        if self.canvas.GetContext():
            self.renderThread.sendCommand(self.renderThread.resize, args=[size])

        event.Skip()


    def onPaint(self, event):
        """ Paint event handler used to initialize the rendering thread """
        if not self.initialized:
            self.initialized = True
            self.renderThread.start()
            time.sleep(0.1)
        event.Skip()


    def onFrame(self, event):
        """ Rendered frame handler """
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
            self.Close()
        elif key == wx.WXK_SPACE: # Send pause command to the rendering thread
            self.renderThread.sendCommand(self.renderThread.pause)
            self.paused = not self.paused
        elif key == ord('T'): # Tweaks dialog
            self._tweaker = PathTracerTweaker(
                self.renderThread.pathtracer,
                parent=self,
                title='Path tracer params'
            )
        elif key == ord('S'): # Toogle render stats printing
            self.renderThread.sendCommand(self.renderThread.toogleStats)
        elif key == ord('D'): # Toogle render dark font for stats
            pt = self.renderThread.pathtracer
            pt.darkFontStats = not pt.darkFontStats


    def onClose(self, e):
        """ Stop the rendering thread and close the OpenGLApp """
        self.renderThread.stop()
        self.renderThread.join()
        self.Destroy()


    ## Other methods

    def getMouse(self):
        """ Get the current mouse status """
        return Mouse(self.x, self.y, self.clickx, self.clicky)



# Main function
def pathtracing(size):
    app = wx.App()
    pathtracer = OpenGLApp(None, -1, 'Realtime GLSL pathtracer', size=size)
    pathtracer.Show()
    app.MainLoop()
