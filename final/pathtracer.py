try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"

try:
    import numpy as np
except ImportError:
    raise ImportError, "Required dependency Numpy not present"


import ctypes, random, threading, time
from framebuffer import Framebuffer
from mouse import Mouse
from program import Program
from shader import Shader, SHADER_STAGE
from texture import Texture
from utils import enum, now


FRAME_SCHEME = enum('ON_DEMAND', 'CONTINUOUS')


class PathTracer:
    """ GLSL path tracer """

    def __init__(self):

        # Has the path tracer been initialized?
        self.initialized = False

        # Creation time of the path tracer
        self.startTime = 0

        # Frame update scheme: on demand or continuous
        self.frameScheme = FRAME_SCHEME.CONTINUOUS

        # Path tracer target size
        self.size = None
        self.resized = True

        # Path tracer program
        self.ptProgram = None

        # Work framebuffer and work texture
        self.workFBO = None
        self.workTexture = None

        # Accumulator program, FBO and texture
        self.accProgram = None
        self.accFBO = None
        self.accTexture = None

        # Final program, FBO and texture(averaging and tonemapping)
        self.finalProgram = None
        self.finalFBO = None
        self.finalTexture = None

        # Fullscreen quad vertex buffer
        self.fullscreenQuadVertexBuffer = None

        # Textures
        self.textures = []

        # Measured frame rate in ms
        self.framerate = 0

        # Time when scene started to be rendered
        # (reset each time the scene changes)
        self.renderStartTime = 0

        # Elapsed time since the current scene rendering started (in s)
        self.renderTime = 0

        # Print stats on screen?
        self.printStats = True

        # Use dark font for stats?
        self.darkFontStats = False

        # Number of iterations since last reset
        self.iterations = 0

        # Last program update time
        self.lastProgramUpdateTime = 0

        # Last mouse state
        self.mouse = Mouse(-1, -1, -1, -1)

        # PathTracer tweak values
        self.tweaks = [1.0 for _ in xrange(4)]
        self.tweaked = False


    def init(self, size):
        """ Initialize the pathtracer """

        if not self.initialized:

            # Must be first because other commands take time
            # and init would be re-entered otherwise
            self.initialized = True

            self.size = size
            self._createPathTracingProgram()
            self._createAccumulatorProgram()
            self._createFinalProgram()
            self._createWorkFBO()
            self._createAccFBO()
            self._createFinalFBO()
            self._createQuadBuffer()
            self._loadTextures()
            self.startTime  = now()
            self.renderStartTime = now()


    def render(self, *args, **kwargs):
        """ Render a frame if necessary """

        if self.initialized:

            beg = now()

            # Pre-frame handler
            needsFrame = self._preFrame(*args, **kwargs)

            # Render a frame if required
            if needsFrame:

                self.iterations += 1

                # Take one or several samples per pixel
                self._pathtrace()

                # Accumulate radiance
                self._accumulate()

                # Average radiance and tonemap
                self._tonemap()

                # Display
                self._display()

                # Give control to the path tracer owner
                # in order for it to call swapBuffers()
                yield self.iterations

                # Post-frame handler
                # Must be performed after swapBuffers()
                self._postFrame()

            end = now()
            self.renderTime = (end - self.renderStartTime)
            self.framerate = (end - beg) * 1000


    def resize(self, size):
        """ Resize the path tracer """
        self.size = size
        self.resized = True
        if self.workTexture: self.workTexture.resize(size)
        if self.accTexture: self.accTexture.resize(size)
        if self.finalTexture: self.finalTexture.resize(size)
        w, h = size
        glViewport(0, 0, w, h)
        glScissor(0, 0, w, h)


    def addTexture(self, texture):
        """ Add a texture """
        self.textures.append(texture)


    def setTweakValue(self, value, i):
        """ Set a tweak value """
        self.tweaks[i] = value
        self.tweaked = True


    ############################### Initialization #############################

    def _createProgram(self, vertex, fragment):
        """ Create an OpenGL program """
        program = Program()
        vs = Shader(SHADER_STAGE.VERTEX)
        fs = Shader(SHADER_STAGE.FRAGMENT)
        vs.loadFromFile(vertex)
        fs.loadFromFile(fragment)
        program.attachShader(vs)
        program.attachShader(fs)
        program.link()
        return program


    def _createPathTracingProgram(self):
        """ Create the pathtracing program """
        self.ptProgram = self._createProgram(
            "assets/shaders/main.vert",
            "assets/shaders/main.frag"
        )


    def _createAccumulatorProgram(self):
        """ Create the accumulator program """
        self.accProgram = self._createProgram(
            "assets/shaders/accumulator.vert",
            "assets/shaders/accumulator.frag"
        )


    def _createFinalProgram(self):
        """ Create the final (tonemap) program """
        self.finalProgram = self._createProgram(
            "assets/shaders/final.vert",
            "assets/shaders/final.frag"
        )


    def _createWorkFBO(self):
        """ Create the work framebuffer and work texture """
        self.workTexture = Texture()
        self.workTexture.create(self.size, GL_RGB32F, GL_RGB, GL_FLOAT)
        self.workFBO = Framebuffer()
        self.workFBO.create()
        self.workFBO.attachTexture(GL_COLOR_ATTACHMENT0, self.workTexture)
        self.workFBO.finalize()


    def _createAccFBO(self):
        """ Create the accumulator framebuffer and accumulator texture """
        self.accTexture = Texture()
        self.accTexture.create(self.size, GL_RGB32F, GL_RGB, GL_FLOAT)
        self.accFBO = Framebuffer()
        self.accFBO.create()
        self.accFBO.attachTexture(GL_COLOR_ATTACHMENT0, self.accTexture)
        self.accFBO.finalize()


    def _createFinalFBO(self):
        """ Create the final framebuffer and final texture """
        self.finalTexture = Texture()
        self.finalTexture.create(self.size, GL_RGB32F, GL_RGB, GL_FLOAT)
        self.finalFBO = Framebuffer()
        self.finalFBO.create()
        self.finalFBO.attachTexture(GL_COLOR_ATTACHMENT0, self.finalTexture)
        self.finalFBO.finalize()


    def _createQuadBuffer(self):
        """ Create the fullscreen quad vertex buffer """

        # NDC fullscreen quad
        ndcQuad = np.array([(-1,-1), (-1,1), (1,-1), (1,1)], dtype=np.float32)

        # Create and fill vertex buffer of the NDC quad
        self.fullscreenQuadVertexBuffer = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.fullscreenQuadVertexBuffer)
        glBufferData(GL_ARRAY_BUFFER, ndcQuad.nbytes, ndcQuad, GL_STATIC_DRAW)

        # Set buffer layout
        loc = glGetAttribLocation(self.ptProgram.id, "VertexPosition")
        glEnableVertexAttribArray(loc)
        glBindBuffer(GL_ARRAY_BUFFER, self.fullscreenQuadVertexBuffer)
        glVertexAttribPointer(loc, 2, GL_FLOAT, False, 0, ctypes.c_void_p(0))


    def _loadTextures(self):
        """ Load some textures used by the shaders """

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


    ################################# Runtime ##################################

    def _updateMouse(self, mouse):
        """ Update the mouse and return if there was any movement """
        if mouse.x != self.mouse.x or \
           mouse.y != self.mouse.y or \
           mouse.clickx != self.mouse.clickx or \
           mouse.clicky != self.mouse.clicky:
            self.mouse = mouse
            return True
        return False


    def _updatePrograms(self):
        """ Update the programs and return if there was any update """
        newProgram = False
        n = now()
        if float(n - self.lastProgramUpdateTime) > 1.0:
            self.lastProgramUpdateTime = n
            newProgram |= self.ptProgram.reloadIfNewer()
            newProgram |= self.accProgram.reloadIfNewer()
            newProgram |= self.finalProgram.reloadIfNewer()
        return newProgram


    def _preFrame(self, *args, **kwargs):
        """
            Pre frame handler: update mouse, programs and textures.
            Return if we need to generate a new frame.
        """

        needsFrame = False

        # Resized
        if self.resized:
            needsFrame = True

        # Mouse
        mouseMoved = False
        if 'mouse' in kwargs:
            mouseMoved = self._updateMouse(kwargs['mouse'])

        # Check if some programs have been updated
        newProgram = self._updatePrograms()

        # Tweaks
        if self.tweaked:
            needsFrame = True

        # Frame scheme
        if self.frameScheme == FRAME_SCHEME.CONTINUOUS:
            needsFrame |= True
        elif self.frameScheme == FRAME_SCHEME.ON_DEMAND:
            needsFrame |= newProgram or mouseMoved
        else:
            print "Unknown frame scheme: {}".format(self.frameScheme)

        # Check if we need to reset the path tracing data
        reset = self.resized or mouseMoved or newProgram or self.tweaked
        if self.iterations == 0 or reset: self._reset()

        self.resized = False
        self.tweaked = False

        return needsFrame


    def _postFrame(self, *args, **kwargs):
        """ Post frame handler """
        # /!\ Required to make sure the OpenGL commands are done before
        #     performing the next iteration
        #     (because the rendering is running in a separate thread)
        glFinish()



    def _drawFullscreenQuad(self):
        """ Draw a fullscreen quad in NDC """
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)


    def _pathtrace(self):
        """ Perform one iteration of path tracing """

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

        # Iteration number
        glUniform1i(glGetUniformLocation(self.ptProgram.id, "uIterations"), self.iterations)

        # Number of samples (rays/paths) to take
        samples = 1 #if self.iterations < 10 else 4
        glUniform1i(glGetUniformLocation(self.ptProgram.id, "uSamples"), int(samples))

        ### Path trace ###
        self.workFBO.bind(GL_DRAW_FRAMEBUFFER)
        self._drawFullscreenQuad()


    def _accumulate(self):
        """ Accumulate current frame with previously rendered ones """

        self.accProgram.bind()
        glUniform1i(glGetUniformLocation(self.accProgram.id, "uWorkTexture"), 8)
        glActiveTexture(GL_TEXTURE0 + 8)
        glBindTexture(GL_TEXTURE_2D, self.workTexture.id)

        glEnable(GL_BLEND)
        glBlendFunc(GL_ONE, GL_ONE)
        self.accFBO.bind(GL_DRAW_FRAMEBUFFER)
        self._drawFullscreenQuad()
        glDisable(GL_BLEND)


    def _tonemap(self):
        """ Average and tonemap the accumulated radiance """
        self.finalProgram.bind()
        w, h = self.size
        glUniform2f(glGetUniformLocation(self.finalProgram.id, "uResolution"), w, h)
        glUniform1i(glGetUniformLocation(self.finalProgram.id, "uIterations"), self.iterations)
        glUniform1i(glGetUniformLocation(self.finalProgram.id, "uAccumulator"), 10)
        glUniform1f(glGetUniformLocation(self.finalProgram.id, "uFramerate"), self.framerate)
        glUniform1f(glGetUniformLocation(self.finalProgram.id, "uRenderTime"), self.renderTime)
        glUniform1i(glGetUniformLocation(self.finalProgram.id, "uPrintStats"), self.printStats)
        glUniform1i(glGetUniformLocation(self.finalProgram.id, "uDarkFont"), self.darkFontStats)
        glActiveTexture(GL_TEXTURE0 + 10)
        glBindTexture(GL_TEXTURE_2D, self.accTexture.id)
        self.finalFBO.bind(GL_DRAW_FRAMEBUFFER)
        self._drawFullscreenQuad()


    def _display(self):
        """ Display the final image to the screen """
        w, h = self.size
        self.finalFBO.bind(GL_READ_FRAMEBUFFER)
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
        glBlitFramebuffer(0, 0, w, h, 0, 0, w, h, GL_COLOR_BUFFER_BIT, GL_LINEAR)


    def _reset(self):
        """ Reset the path tracing data """
        self.iterations = 0
        self.renderTime = 0
        self.renderStartTime = now()
        glClearColor(0, 0, 0, 0)
        self.workFBO.bind(GL_DRAW_FRAMEBUFFER)
        glClear(GL_COLOR_BUFFER_BIT)
        self.accFBO.bind(GL_DRAW_FRAMEBUFFER)
        glClear(GL_COLOR_BUFFER_BIT)
        self.finalFBO.bind(GL_DRAW_FRAMEBUFFER)
        glClear(GL_COLOR_BUFFER_BIT)

