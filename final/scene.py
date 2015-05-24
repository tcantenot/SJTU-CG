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
from texture import *
from framebuffer import *

#TODO:
# - program location cache (need to be emptied after each program reload...)


FRAME_SCHEME = enum('ON_DEMAND', 'CONTINUOUS')

class Scene(object):

    def __init__(self):
        pass

    def init(self):
        pass

    def render(self, *args, **kwargs):
        pass

class Demo(Scene):
    """ Small demo class used to render a scene """

    def __init__(self, size=(0, 0)):
        Scene.__init__(self)

        self.initialized = False
        self.vertexbuffer = None
        self.size = size
        self.startTime = 0

        self.mouse = Mouse(-1, -1, -1, -1)
        self.frameScheme = FRAME_SCHEME.ON_DEMAND
        #self.frameScheme = FRAME_SCHEME.CONTINUOUS

        self.program = Program()
        self.vs = Shader(SHADER_STAGE.VERTEX)
        self.fs = Shader(SHADER_STAGE.FRAGMENT)

        self.resized = True

        # Textures
        self.textures = []

        # Framebuffer and work texture
        self.framebuffer = Framebuffer()
        self.worktexture = Texture()
        self.framebuffer.attachTexture(GL_COLOR_ATTACHMENT0, self.worktexture)

        # Scene tweak values
        self.tweaks = [1.0 for _ in xrange(4)]
        self.tweaked = False

        # TODO
        self.camera = None


    def init(self, size=None):
        """ Initialize the scene """

        if not self.initialized:
            if size: self.size = size
            self._createProgram()
            self._createBuffer()
            self._loadTextures()
            self.initialized = True
            self.startTime = time.time()


    def render(self, *args, **kwargs):
        """ Render a frame if necessary """

        needsFrame = False


        if self.initialized:

            if self.resized:
                needsFrame = True
                self.resized = False

            if self.tweaked:
                needsFrame = True
                self.tweaked = False

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
                needsFrame |= True
            elif self.frameScheme == FRAME_SCHEME.ON_DEMAND:
                needsFrame |= reloaded or mouseMoved
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
                glUniform4f(
                    glGetUniformLocation(self.program.id, "uMouse"),
                    self.mouse.x, self.mouse.y, self.mouse.clickx, self.mouse.clicky
                )

                # Textures
                for i, tex in enumerate(self.textures):
                    glUniform1i(glGetUniformLocation(self.program.id, "uTexture{}".format(i)), i)
                    glActiveTexture(GL_TEXTURE0 + i)
                    glBindTexture(GL_TEXTURE_2D, tex.id)

                # Tweaks
                glUniform4f(
                    glGetUniformLocation(self.program.id, "uTweaks"),
                    self.tweaks[0], self.tweaks[1], self.tweaks[2], self.tweaks[3]
                )

                ### Draw ###

                self.framebuffer.bind(GL_DRAW_FRAMEBUFFER)
                glClear(GL_COLOR_BUFFER_BIT)

                fragCount = 4
                glUniform1i(glGetUniformLocation(self.program.id, "uFragCount"), fragCount);

                for i in xrange(fragCount):
                    glUniform1i(glGetUniformLocation(self.program.id, "uFragIndex"), i);
                    self.framebuffer.bind()
                    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
                    w, h = self.size
                    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
                    self.framebuffer.bind(GL_READ_FRAMEBUFFER)
                    glBlitFramebuffer(0, 0, w, h, 0, 0, w, h, GL_COLOR_BUFFER_BIT, GL_LINEAR)
                    yield True, i
                    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
                    glClear(GL_COLOR_BUFFER_BIT)


    def resize(self, size):
        """ Resize hook """
        self.size = size
        self.worktexture.resize(size)
        self.framebuffer.finalize()
        self.resized = True
        w, h = size
        glViewport(0, 0, w, h)


    def addTexture(self, texture):
        self.textures.append(texture)

    def setTweakValue(self, value, i):
        """ Set a tweak value """
        if i < 4:
            self.tweaks[i] = value
            self.tweaked = True

    def _createProgram(self):
        """ Create the program used by the scene """

        self.vs.loadFromFile("assets/shaders/main.vert")
        self.fs.loadFromFile("assets/shaders/main.frag")
        self.program.attachShader(self.vs)
        self.program.attachShader(self.fs)
        self.program.link()
        self.program.bind()


    def _createBuffer(self):
        """ Create the fullscreen quad vertex buffer """

        # NDC fullscreen quad
        ndcQuad = np.array([(-1, -1), (-1, +1), (+1, -1), (+1, +1)], dtype=np.float32)

        # Create and fill vertex buffer of the NDC quad
        self.vertexbuffer = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vertexbuffer)
        glBufferData(GL_ARRAY_BUFFER, ndcQuad.nbytes, ndcQuad, GL_STATIC_DRAW)

        # Set buffer layout
        location = glGetAttribLocation(self.program.id, "VertexPosition")
        glEnableVertexAttribArray(location)
        glBindBuffer(GL_ARRAY_BUFFER, self.vertexbuffer)
        glVertexAttribPointer(location, 2, GL_FLOAT, False, 0, ctypes.c_void_p(0))


    def _loadTextures(self):
        textures = [
            "assets/textures/noise_1.jpg",
            "assets/textures/noise_2.jpg",
            "assets/textures/texture_1.jpg",
            "assets/textures/texture_2.jpg",
            "assets/textures/texture_3.jpg"
        ]

        for f in textures:
            texture = Texture()
            if texture.loadFromFile(f):
                self.addTexture(texture)
