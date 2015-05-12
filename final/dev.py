try:
    import wx
    from wx import glcanvas
except ImportError:
    raise ImportError, "Required dependency wx.glcanvas not present"

try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"

from scene import Scene, Demo
from utils import now
from mouse import Mouse


class GLFrame(wx.Frame):
    """A simple class for using OpenGL with wxPython."""

    # TODO: improve construction
    def __init__(self, parent, id, title, pos=wx.DefaultPosition,
                 size=wx.DefaultSize, style=wx.DEFAULT_FRAME_STYLE,
                 name='frame'):

        style = wx.DEFAULT_FRAME_STYLE | wx.NO_FULL_REPAINT_ON_RESIZE

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

        # Timer
        FRAME_ID = 0x42
        self.timer = wx.Timer(self.canvas, FRAME_ID)
        self.canvas.Bind(wx.EVT_TIMER, self.onFrame, id=FRAME_ID)
        fps = 60
        dt = 1000.0 / fps
        self.timer.Start(dt)

        # Mouse positions
        self.lastx = self.x = 30
        self.lasty = self.y = 30

        # Frame size
        self.size = size

        # Scene
        self.scene = None

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


    def onResize(self, event):
        """Process the resize event."""
        size = self.size = self.getGLExtents()
        if self.canvas.GetContext():
            # Make sure the frame is shown before calling SetCurrent.
            if self.scene: self.scene.resize(size)
            self.Show()
            self.canvas.SetCurrent()
            self.canvas.Refresh(False)
        event.Skip()


    def onPaint(self, event):
        """Process the paint event."""
        # Activate the OpenGL context of the canvas
        self.canvas.SetCurrent()
        # Initialize Scene if required
        if self.scene and not self.scene.initialized:
            self.scene.init(self.size)


    def onFrame(self, evt):
        """Generate a frame."""
        #print "On Frame"
        if evt.GetId() == self.timer.GetId():
            updated = self.scene.render(mouse=Mouse(self.x, self.y))
            if updated: self.swapBuffers()
            evt.Skip()

    def onMouseDown(self, evt):
        self.canvas.CaptureMouse()
        self.x, self.y = self.lastx, self.lasty = evt.GetPosition()
        #print "Mouse down ({}, {})".format(self.x, self.y)


    def onMouseUp(self, evt):
        self.canvas.ReleaseMouse()
        x, y = evt.GetPosition()
        #print "Mouse up ({}, {})".format(x, y)


    def onMouseMotion(self, evt):
        if evt.Dragging() and evt.LeftIsDown():
            self.lastx, self.lasty = self.x, self.y
            self.x, self.y = evt.GetPosition()
            self.canvas.Refresh(False)
            #print "Mouse motion ({}, {})".format(self.x, self.y)


    def onKeyDown(self, e):
        key = e.GetKeyCode()
        if key == wx.WXK_ESCAPE:
            self.timer.Stop()
            self.Close()




if __name__ == "__main__":
    app = wx.App()
    frame = GLFrame(None, -1, 'GL Window', size=(600, 480))
    frame.scene = Demo()
    frame.Show()
    app.MainLoop()
