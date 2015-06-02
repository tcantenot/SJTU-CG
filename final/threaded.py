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
from scene import Scene, Demo
from tweaker import SceneTweaker


# Frame event
EVT_FRAME_TYPE = wx.NewEventType()
EVT_FRAME = wx.PyEventBinder(EVT_FRAME_TYPE, 1)

class FrameEvent(wx.PyCommandEvent):
    """ Event to signal that a frame has been rendered """

    def __init__(self, etype, eid):
        """Creates the event object"""
        wx.PyCommandEvent.__init__(self, etype, eid)
        self.number = -1
        self.fragIndex = -1



class RenderThread(threading.Thread):
    def __init__(self, parent):

        threading.Thread.__init__(self)

        # OpenGLApp parent
        self._parent = parent

        # wx._glcontext
        self._glcontext = None

        # Scene
        self._scene = None

        # Scene tweaker dialog
        self._sceneTweaker = None #SceneTweaker(parent=self._parent, scene=None, title='Scene parameters')

        # FIXME:
        self.initialized = False

        # TODO: make property
        # Pause/Resume
        self.paused = False

        # FIXME: find a better way
        self._stop = False

        # Queue containing the commands sent by the main app
        self._commandQueue = CommandQueue()


    def run(self):

        self.initialized = True

        self._glcontext = glcanvas.GLContext(self._parent.canvas)
        self._glcontext.SetCurrent(self._parent.canvas)

        self.scene = Demo()
        self.scene.init(self._parent.size)

        while True:

            # Process commands sent by the main app
            self._processCommands()

            # Render
            if not self.paused:
                mouse = self._parent.getMouse()
                for updated, fragIndex in self.scene.render(mouse=mouse):
                    if not updated: continue
                    frame = FrameEvent(EVT_FRAME_TYPE, -1)
                    frame.number = self.scene.iterations
                    frame.fragIndex = fragIndex
                    wx.PostEvent(self._parent, frame)

            if self._stop: break


    def resize(self, size):
        print "Resize: {}".format(size)
        if self.scene: self.scene.resize(size)

    def pause(self):
        self.paused = not self.paused
        print "{}".format("Pause" if self.paused else "Resume")

    def stop(self):
        self._stop = True

    def sendCommand(self, func, args=[], kwargs={}):
        self._commandQueue.enqueue(func, args, kwargs)

    @property
    def scene(self):
        return self._scene

    @scene.setter
    def scene(self, s):
        self._scene = s
        if self._sceneTweaker:
            self._sceneTweaker.scene = s

    def _processCommands(self):
        if not self._commandQueue.empty():
            worker = CommandWorker(self._commandQueue)
            worker.run()


class OpenGLApp(wx.Frame):
    """ OpenGL application with wxPython """

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
        """ Paint event handler used to perform the scene initialization """
        if not self.initialized:
            self.initialized = True
            self.renderThread.start()
            time.sleep(0.1)
        event.Skip()


    def onFrame(self, event):
        """ Scene frame handler """
        self.swapBuffers()
        #print "Frame {}".format(event.number)


    def onMouseDown(self, event):
        """ Mouse button down handler """
        if not self.paused:
            self.canvas.CaptureMouse()
            self.x, self.y = event.GetPosition()
            self.y = self.size[1] - self.y # Invert y-axis
            self.lastx, self.lasty = self.x, self.y
            self.clickx, self.clicky = self.x, self.y
            #print "Mouse down ({}, {})".format(self.x, self.y)


    def onMouseUp(self, event):
        """ Mouse button up handler """
        if not self.paused:
            self.canvas.ReleaseMouse()
            x, y = event.GetPosition()
            #print "Mouse up ({}, {})".format(x, y)


    def onMouseMotion(self, event):
        """ Mouse moved handler """
        if not self.paused:
            if event.Dragging() and event.LeftIsDown():
                self.lastx, self.lasty = self.x, self.y
                self.x, self.y = event.GetPosition()
                self.y = self.size[1] - self.y # Invert y-axis
                self.canvas.Refresh(False)
                #print "Mouse motion ({}, {})".format(self.x, self.y)


    def onKeyDown(self, e):
        """ Key pressed handler """
        key = e.GetKeyCode()
        if key == wx.WXK_ESCAPE: # Close the OpenGLApp
            self.Close()
        elif key == wx.WXK_SPACE: # Send pause command to the rendering thread
            self.renderThread.sendCommand(self.renderThread.pause)
            self.paused = not self.paused


    def onClose(self, e):
        """ Stop the rendering thread and close the OpenGLApp """
        self.renderThread.stop()
        self.renderThread.join()
        self.Destroy()


    ## Other methods

    def getMouse(self):
        """ Get the current mouse status """
        return Mouse(self.x, self.y, self.clickx, self.clicky)

