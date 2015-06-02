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
from scene import Scene, Demo
from utils import now
from mouse import Mouse
from tweaker import SceneTweaker
from command import CommandWorker, CommandQueue


# Frame event
_EVT_FRAME = wx.NewEventType()
EVT_FRAME = wx.PyEventBinder(_EVT_FRAME, 1)

# TODO: update FrameEvent to hold relevant info about the frame
class FrameEvent(wx.PyCommandEvent):
    """Event to signal that a frame has been rendered"""

    def __init__(self, etype, eid, value=None):
        """Creates the event object"""
        wx.PyCommandEvent.__init__(self, etype, eid)
        self._value = value

    def GetValue(self):
        """Returns the value from the event.
        @return: the value of this event
        """
        return self._value


class SceneThread(threading.Thread):

    def __init__(self, parent):

        threading.Thread.__init__(self)

        # GLFrame parent
        self._parent = parent

        # wx._glcontext
        self._glcontext = None

        # Scene
        self._scene = None

        # Scene tweaker dialog
        self._sceneTweaker = SceneTweaker(parent=self._parent, scene=None, title='Scene parameters')

        # FIXME:
        self.initialized = False

        # TODO: make property
        # Pause/Resume
        self._pause = False

        # FIXME: find a better way
        self._stop = False

        # Queue containing the commands sent by the main app
        self._commandQueue = CommandQueue()


    def run(self):

        self.initialized = True

        self._glcontext = glcanvas._glcontext(self._parent.canvas)
        self._glcontext.SetCurrent(self._parent.canvas)

        self.scene = Demo()
        self.scene.init(self._parent.size)

        while True:
            if not self._pause:
                mouse = Mouse(
                    self._parent.x, self._parent.y,
                    self._parent.clickx, self._parent.clicky
                )
                for updated, fragIndex in self.scene.render(mouse=mouse):
                    if updated:
                        if not self._stop:
                            evt = FrameEvent(_EVT_FRAME, -1, fragIndex)
                            wx.PostEvent(self._parent, evt)


            # Process commands sent by the main app
            self._processCommands()

            # FIXME
            #time.sleep(0.1)

            if self._stop: break

    def resize(self, size):
        print "Resize: {}".format(size)
        if self.scene: self.scene.resize(size)

    def pause(self):
        self._pause = not self._pause
        print "{}".format("Pause" if self._pause else "Resume")

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


class GLFrame(wx.Frame):
    """A simple class for using OpenGL with wxPython."""

    # TODO: improve construction
    def __init__(self, parent, id, title, pos=wx.DefaultPosition,
                 size=wx.DefaultSize, style=wx.DEFAULT_FRAME_STYLE,
                 name='frame'):

        style = wx.DEFAULT_FRAME_STYLE #| wx.NO_FULL_REPAINT_ON_RESIZE

        super(GLFrame, self).__init__(parent, id, title, pos, size, style, name)

        # Canvas attributes
        attribList = (glcanvas.WX_GL_RGBA, # RGBA
                      glcanvas.WX_GL_DOUBLEBUFFER, # Double Buffered
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

        # Frame event produced by the scene thread
        self.Bind(EVT_FRAME, self.onFrame)

        # Close event
        self.Bind(wx.EVT_CLOSE, self.onClose)

        # Mouse positions
        self.clickx = self.lastx = self.x = size[0] / 2.0
        self.clicky = self.lasty = self.y = size[1] / 2.0

        # Frame size
        self.size = size

        # Scene thread
        self.sceneThread = SceneThread(self)

        # Pause rendering
        self.pause = False

        # Give the focus to the canvsas
        self.canvas.SetFocus()


    # Canvas Proxy Methods

    def getGLExtents(self):
        """Get the extents of the OpenGL canvas."""
        return self.canvas.GetClientSize()


    def swapBuffers(self):
        """Swap the OpenGL buffers."""
        self.canvas.SwapBuffers()


    # wxPython Window Handlers

    def onEraseBackground(self, event):
        """Process the erase background event."""
        pass # Do nothing, to avoid flashing on MSWin


    # FIXME
    def onResize(self, event):
        """Process the resize event."""

        size = self.getGLExtents()

        # Keep ratio of mouse positions when resized
        self.x = self.x * size[0] / self.size[0]
        self.y = self.y * size[1] / self.size[1]
        self.lastx = self.lastx * size[0] / self.size[0]
        self.lasty = self.lasty * size[1] / self.size[1]
        self.clickx = self.clickx * size[0] / self.size[0]
        self.clicky = self.clicky * size[1] / self.size[1]

        self.size = size

        if self.canvas.GetContext():

            # Send resize command to the scene thread
            self.sceneThread.sendCommand(self.sceneThread.resize, args=[size])

            # FIXME: check lines below
            self.Show()
            self.canvas.Refresh(False)
        event.Skip()


    # FIXME
    def onPaint(self, event):
        """Process the paint event."""
        # Start scene thread if not done yet
        if not self.sceneThread.initialized:
            self.sceneThread.start()
            time.sleep(0.1)
        event.Skip()


    # FIXME
    def onFrame(self, event):
        """A frame has been generated"""
        self.swapBuffers()


    def onMouseDown(self, event):
        self.canvas.CaptureMouse()
        self.x, self.y = event.GetPosition()
        self.y = self.size[1] - self.y # Invert y-axis
        self.lastx, self.lasty = self.x, self.y
        self.clickx, self.clicky = self.x, self.y
        #print "Mouse down ({}, {})".format(self.x, self.y)


    def onMouseUp(self, event):
        self.canvas.ReleaseMouse()
        x, y = event.GetPosition()
        #print "Mouse up ({}, {})".format(x, y)


    def onMouseMotion(self, event):
        if event.Dragging() and event.LeftIsDown():
            self.lastx, self.lasty = self.x, self.y
            self.x, self.y = event.GetPosition()
            self.y = self.size[1] - self.y # Invert y-axis
            self.canvas.Refresh(False)
            #print "Mouse motion ({}, {})".format(self.x, self.y)


    def onKeyDown(self, e):
        key = e.GetKeyCode()

        # Close the GLFrame
        if key == wx.WXK_ESCAPE:
            self.Close()

        # Send pause command to the scene thread
        elif key == wx.WXK_SPACE:
            self.sceneThread.sendCommand(self.sceneThread.pause)


    def onClose(self, e):
        """ Stop the scene thread and close the GLFrame """
        self.sceneThread.stop()
        self.sceneThread.join()
        self.Destroy()


if __name__ == "__main__":
    app = wx.App()
    frame = GLFrame(None, -1, 'GL Window', size=(600, 480))
    frame.scene = Demo()
    frame.Show()
    app.MainLoop()
