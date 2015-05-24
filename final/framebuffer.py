try:
    from OpenGL.GL.framebufferobjects import *
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"


class Framebuffer(object):

    def __init__(self):
        self.id = 0
        self.textures = { }

        self.id = glGenFramebuffers(1)
        self.bind()

    def attachTexture(self, attachment, texture):
        self.textures[attachment] = texture

    def finalize(self):
        for a, t in self.textures.iteritems():
            glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, a, GL_TEXTURE_2D, t.id, 0)

        glDrawBuffer(GL_COLOR_ATTACHMENT0)

        status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
        if status != GL_FRAMEBUFFER_COMPLETE:
            print "Error: incomplete framebuffer (status: {})".format(status)
            return False

        return True

    def bind(self, target=GL_FRAMEBUFFER):
        if id != 0: glBindFramebuffer(target, self.id)

    def unbind(self, target=GL_FRAMEBUFFER):
        glBindFramebuffer(target, 0)
