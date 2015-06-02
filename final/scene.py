try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"

try:
    import numpy as np
except ImportError:
    raise ImportError, "Required dependency Numpy not present"


import ctypes, time, random
import threading
from mouse import Mouse
from utils import enum, now
from shader import *
from program import *
from texture import *
from framebuffer import *
from grid import *


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
        #self.frameScheme = FRAME_SCHEME.ON_DEMAND
        self.frameScheme = FRAME_SCHEME.CONTINUOUS

        self.ptProgram = None

        self.resized = True

        # Textures
        self.textures = []

        # Work framebuffer and work texture
        self.workFBO = None
        self.workTexture = None

        self.iterations = 0

        self.accProgram = None
        self.accFBO = None
        self.accTexture = None

        self.finalProgram = None


        # Scene tweak values
        self.tweaks = [1.0 for _ in xrange(4)]
        self.tweaked = False

        # TODO
        self.camera = None


    def init(self, size=None):
        """ Initialize the scene """

        if not self.initialized:

            # Must be first because other commands take time
            # and init would be re-entered otherwise
            self.initialized = True

            if size: self.size = size
            self._createPathTracingProgram()
            self._createAccumulatorProgram()
            self._createFinalProgram()
            self._createWorkFBO()
            self._createAccFBO()
            self._createBuffer()
            self._loadTextures()
            self.startTime = time.time()


    def render(self, *args, **kwargs):
        """ Render a frame if necessary """

        needsFrame = False


        if self.initialized:

            if self.resized:
                needsFrame = True

            if self.tweaked:
                needsFrame = True

            # TODO: add check interval to save resources
            # Check if the ptProgram needs to be newProgram
            newProgram = False
            newProgram |= self.ptProgram.reloadIfNewer()
            newProgram |= self.accProgram.reloadIfNewer()
            newProgram |= self.finalProgram.reloadIfNewer()

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
                needsFrame |= newProgram or mouseMoved
            else:
                print "Unknown frame scheme: {}".format(self.frameScheme)

            # Render a frame if required
            if needsFrame:

                ### Send uniforms ###

                self.ptProgram.bind()

                # Current time
                t = float(now() - self.startTime)
                glUniform1f(glGetUniformLocation(self.ptProgram.id, "uTime"), t)

                # Resolution
                w, h = self.size
                glUniform2f(glGetUniformLocation(self.ptProgram.id, "uResolution"), w, h)

                # Mouse
                glUniform4f(
                    glGetUniformLocation(self.ptProgram.id, "uMouse"),
                    self.mouse.x, self.mouse.y, self.mouse.clickx, self.mouse.clicky
                )

                # Textures
                for i, tex in enumerate(self.textures):
                    glUniform1i(glGetUniformLocation(self.ptProgram.id, "uTexture{}".format(i)), i)
                    glActiveTexture(GL_TEXTURE0 + i)
                    glBindTexture(GL_TEXTURE_2D, tex.id)

                # Tweaks
                glUniform4f(
                    glGetUniformLocation(self.ptProgram.id, "uTweaks"),
                    self.tweaks[0], self.tweaks[1], self.tweaks[2], self.tweaks[3]
                )

                ### Draw ###
                #fragCount = 1
                #for fragIndex in self._splitDraw(fragCount):
                    #yield True, fragIndex

                # Check if we need to reset the accumulator
                if self.iterations == 0 or mouseMoved or self.resized \
                    or newProgram or self.tweaked:
                    self._resetAccumulator()


                if True and self.iterations < 6000:

                    # Draw: cast one ray per pixel, accumulate it and eventually display the merge result

                    self.iterations += 1

                    samples = 1
                    #if self.iterations > 10:
                        #samples = 4

                    glUniform1i(glGetUniformLocation(self.ptProgram.id, "uSamples"), int(samples))


                    # Cast one ray pixel and draw result in work texture

                    glUniform1i(glGetUniformLocation(self.ptProgram.id, "uIterations"), self.iterations)
                    self.workFBO.bind(GL_DRAW_FRAMEBUFFER)
                    fragCount = 1
                    for fragIndex in self._splitDraw(fragCount, True):
                        #yield True, fragIndex
                        pass

                    # Add current iteration to accumulator
                    self.accFBO.bind(GL_DRAW_FRAMEBUFFER)

                    self.accProgram.bind()
                    glUniform1i(glGetUniformLocation(self.accProgram.id, "uWorkTexture"), 8)
                    glActiveTexture(GL_TEXTURE0 + 8)
                    glBindTexture(GL_TEXTURE_2D, self.workTexture.id)

                    glEnable(GL_BLEND)
                    glBlendFunc(GL_ONE, GL_ONE)
                    self._drawFullscreenQuad()
                    glDisable(GL_BLEND)

                    # Tonemap and display on screen
                    self.finalProgram.bind()
                    w, h = self.size
                    glUniform2f(glGetUniformLocation(self.finalProgram.id, "uResolution"), w, h)
                    glUniform1i(glGetUniformLocation(self.finalProgram.id, "uSceneTexture"), 10)
                    glActiveTexture(GL_TEXTURE0 + 10)
                    glBindTexture(GL_TEXTURE_2D, self.accTexture.id)
                    glUniform1i(glGetUniformLocation(self.finalProgram.id, "uIterations"), self.iterations)
                    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
                    self._drawFullscreenQuad()

                    yield True, -1
                    glFinish()

            self.resized = False
            self.tweaked = False


    def resize(self, size):
        """ Resize hook """
        self.size = size
        self.resized = True
        if self.workTexture: self.workTexture.resize(size)
        if self.accTexture: self.accTexture.resize(size)
        w, h = size
        glViewport(0, 0, w, h)
        glScissor(0, 0, w, h)



    def addTexture(self, texture):
        self.textures.append(texture)

    def setTweakValue(self, value, i):
        """ Set a tweak value """
        if i < 4:
            self.tweaks[i] = value
            self.tweaked = True

    def _createPathTracingProgram(self):
        """ Create the pathtracing program """
        self.ptProgram = Program()
        vs = Shader(SHADER_STAGE.VERTEX)
        fs = Shader(SHADER_STAGE.FRAGMENT)
        vs.loadFromFile("assets/shaders/main.vert")
        fs.loadFromFile("assets/shaders/main.frag")
        self.ptProgram.attachShader(vs)
        self.ptProgram.attachShader(fs)
        self.ptProgram.link()

    def _createAccumulatorProgram(self):
        """ Create the accumulator program """
        self.accProgram = Program()
        vs = Shader(SHADER_STAGE.VERTEX)
        fs = Shader(SHADER_STAGE.FRAGMENT)
        vs.loadFromFile("assets/shaders/pathtracer/accumulator.vert")
        fs.loadFromFile("assets/shaders/pathtracer/accumulator.frag")
        self.accProgram.attachShader(vs)
        self.accProgram.attachShader(fs)
        self.accProgram.link()

    def _createFinalProgram(self):
        """ Create the final (tonemap) program """
        self.finalProgram = Program()
        vs = Shader(SHADER_STAGE.VERTEX)
        fs = Shader(SHADER_STAGE.FRAGMENT)
        vs.loadFromFile("assets/shaders/pathtracer/final.vert")
        fs.loadFromFile("assets/shaders/pathtracer/final.frag")
        self.finalProgram.attachShader(vs)
        self.finalProgram.attachShader(fs)
        self.finalProgram.link()


    def _createBuffer(self):
        """ Create the fullscreen quad vertex buffer """

        # NDC fullscreen quad
        ndcQuad = np.array([(-1, -1), (-1, +1), (+1, -1), (+1, +1)], dtype=np.float32)

        # Create and fill vertex buffer of the NDC quad
        self.vertexbuffer = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vertexbuffer)
        glBufferData(GL_ARRAY_BUFFER, ndcQuad.nbytes, ndcQuad, GL_STATIC_DRAW)

        # Set buffer layout
        location = glGetAttribLocation(self.ptProgram.id, "VertexPosition")
        glEnableVertexAttribArray(location)
        glBindBuffer(GL_ARRAY_BUFFER, self.vertexbuffer)
        glVertexAttribPointer(location, 2, GL_FLOAT, False, 0, ctypes.c_void_p(0))


    def _createWorkFBO(self):
        """ Create the work framebuffer and work texture """
        self.workFBO = Framebuffer()
        self.workTexture = Texture()
        self.workTexture.create((1, 1), GL_RGB32F, GL_RGB, GL_FLOAT)
        self.workFBO.create()
        self.workFBO.attachTexture(GL_COLOR_ATTACHMENT0, self.workTexture)
        if self.size:
            self.workTexture.resize(self.size)
            self.workFBO.finalize()

    def _createAccFBO(self):
        """ Create the accumulator framebuffer and accumulator texture """
        self.accFBO = Framebuffer()
        self.accTexture = Texture()
        self.accTexture.create((1, 1), GL_RGB32F, GL_RGB, GL_FLOAT)
        self.accFBO.create()
        self.accFBO.attachTexture(GL_COLOR_ATTACHMENT0, self.accTexture)
        if self.size:
            self.accTexture.resize(self.size)
            self.accFBO.finalize()


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


    def _drawFullscreenQuad(self):
        """ Draw a fullscreen quad in NDC """
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)


    def _splitDraw(self, fragCount, display=True):
        """ Split the rendering process into multiple fragments """

        w, h = self.size

        glEnable(GL_SCISSOR_TEST)

        glScissor(0, 0, w, h)
        self.workFBO.bind(GL_DRAW_FRAMEBUFFER)
        #glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
        glClear(GL_COLOR_BUFFER_BIT)

        fragCountX = int(np.floor(np.sqrt(fragCount)))
        fragCountY = fragCount / fragCountX
        fragCount = fragCountX * fragCountY

        glUniform1i(glGetUniformLocation(self.ptProgram.id, "uFragCount"), fragCount);

        dw = (1.0 - (-1.0)) / float(fragCountX)
        dh = (1.0 - (-1.0)) / float(fragCountY)

        #print "Frag count = ({}, {})".format(fragCountX, fragCountY)
        #print "Frag dim = ({}, {})".format(dw, dh)
        #print ""

        #grid = random.sample([random_grid, grid1, grid2], 1)[0]
        grid = grid2

        indices = grid(fragCountX, fragCountY);

        for iteration, k in enumerate(indices):

            i = k % fragCountX
            j = k / fragCountX

            mx = -1.0 + i * dw
            Mx = mx + dw
            my = -1.0 + j * dh
            My = my + dh

            #print "#{}: (i, j) = ({}, {})".format(k, i, j)
            #print "({}, {}) | ({}, {})".format(mx, my, Mx, My)

            glUniform1i(glGetUniformLocation(self.ptProgram.id, "uFragIndex"), k);
            glUniform4f(glGetUniformLocation(self.ptProgram.id, "uFragBounds"), mx, Mx, my, My)

            # [-1, 1] -> [0, 1]
            mx = mx * 0.5 + 0.5
            Mx = Mx * 0.5 + 0.5
            my = my * 0.5 + 0.5
            My = My * 0.5 + 0.5

            glScissor(int(mx*w), int(my*h), int(dw*w), int(dh*h))

            #print "({}, {}) | ({}, {})".format(mx, my, Mx, My)
            #print "({}, {}) | ({}, {})".format(mx*w, my*h, Mx*w, My*h)
            #print ""

            # Select draw buffer of the work framebuffer
            #glDrawBuffer(GL_FRONT if iteration % 2 else GL_BACK)

            # Draw into the work framebuffer
            self.workFBO.bind(GL_DRAW_FRAMEBUFFER)
            self._drawFullscreenQuad()

            if display:
                # Copy content of the work framebuffer  into the screen buffer
                glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
                #glBindFramebuffer(GL_READ_FRAMEBUFFER, 0)
                self.workFBO.bind(GL_READ_FRAMEBUFFER)

                # Select read buffer and the back draw buffer of the screen
                #glReadBuffer(GL_FRONT if iteration % 2 else GL_BACK)
                #glDrawBuffer(GL_BACK)

                # Copy the content of the work framebuffer into the screen's
                glScissor(0, 0, w, h)
                glBlitFramebuffer(0, 0, w, h, 0, 0, w, h, GL_COLOR_BUFFER_BIT, GL_LINEAR)

            # Display the current result
            yield iteration


    def _resetAccumulator(self):
        self.iterations = 0
        glClearColor(0, 0, 0, 0)
        self.workFBO.bind(GL_DRAW_FRAMEBUFFER)
        glClear(GL_COLOR_BUFFER_BIT)
        self.accFBO.bind(GL_DRAW_FRAMEBUFFER)
        glClear(GL_COLOR_BUFFER_BIT)
