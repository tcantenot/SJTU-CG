try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"
try:
    import numpy as np
except ImportError:
    raise ImportError, "Required dependency Numpy not present"


import ctypes
import time
from mouse import Mouse
from utils import enum, now
from shader import *
from program import *


FRAME_SCHEME = enum('ON_DEMAND', 'CONTINUOUS')

class Scene(object):

    def __init__(self):
        pass

    def init(self):
        pass

    def render(self, *args, **kwargs):
        pass

class Demo(Scene):

    def __init__(self, size=(0, 0)):
        Scene.__init__(self)

        self.initialized = False
        self.vertexbuffer = None
        self.size = size
        self.startTime = 0

        self.mouse = Mouse(-1, -1)
        self.frameScheme = FRAME_SCHEME.ON_DEMAND

        self.program = Program()
        self.vs = Shader(SHADER_STAGE.VERTEX)
        self.fs = Shader(SHADER_STAGE.FRAGMENT)


    def init(self, size=None):
        if not self.initialized:
            if size: self.size = size
            self._createProgram()
            self._createBuffer()
            self.initialized = True
            self.startTime = time.time()


    def render(self, *args, **kwargs):

        needsFrame = False

        if self.initialized:

            # TODO: add check interval to save resources
            # Check if the program needs to be reloaded
            reloaded = self.program.reloadIfNewer()
            if reloaded:
                self.program.bind()

            # Mouse
            mouseMoved = False
            if 'mouse' in kwargs:
                mouse = kwargs['mouse']
                if mouse.x != self.mouse.x or mouse.y != self.mouse.y:
                    self.mouse = mouse
                    mouseMoved = True

            if self.frameScheme == FRAME_SCHEME.CONTINUOUS:
                needsFrame = True
            elif self.frameScheme == FRAME_SCHEME.ON_DEMAND:
                needsFrame = reloaded or mouseMoved
            else:
                print "Unknown frame scheme: {}".format(self.frameScheme)

            if needsFrame:
                ### Send uniforms ###

                # Current time
                t = float(now() - self.startTime)
                glUniform1f(glGetUniformLocation(self.program.id, "uTime"), t)

                # Resolution
                w, h = self.size
                res = np.array([w, h], dtype=np.float32)
                glUniform2f(glGetUniformLocation(self.program.id, "uResolution"), res[0], res[1])

                # Mouse
                glUniform2f(glGetUniformLocation(self.program.id, "uMouse"), self.mouse.x, self.mouse.y)

                ### Draw ###
                glClear(GL_COLOR_BUFFER_BIT)
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)

        return needsFrame


    def resize(self, size):
        self.size = size
        w, h = size
        glViewport(0, 0, w, h)

    def _createProgram(self):
        self.vs.loadFromFile("assets/shaders/scene.vert")
        self.fs.loadFromFile("assets/shaders/scene.frag")
        self.program.attachShader(self.vs)
        self.program.attachShader(self.fs)
        self.program.link()
        self.program.bind()


    def _createBuffer(self):

        ndcQuad = np.array([(-1, -1), (-1, +1), (+1, -1), (+1, +1)], dtype=np.float32)

        self.vertexbuffer = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vertexbuffer)
        glBufferData(GL_ARRAY_BUFFER, ndcQuad.nbytes, ndcQuad, GL_STATIC_DRAW)

        location = glGetAttribLocation(self.program.id, "VertexPosition")
        glEnableVertexAttribArray(location)
        glBindBuffer(GL_ARRAY_BUFFER, self.vertexbuffer)
        glVertexAttribPointer(location, 2, GL_FLOAT, False, 0, ctypes.c_void_p(0))
