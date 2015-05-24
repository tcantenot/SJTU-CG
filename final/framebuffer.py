try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"


class Framebuffer(object):
    """ Wrapper for the OpenGL frambuffer object """

    def __init__(self):
        self.id = 0
        self.textures = { }

    def create(self):
        """ Create the underlying OpenGL framebuffer object """
        self.id = glGenFramebuffers(1)


    def destroy(self):
        """ Destroy the underlying OpenGL framebuffer object """
        self.bind()
        for a, t in self.textures.iteritems():
            glFramebufferTexture(GL_DRAW_FRAMEBUFFER, a, 0, 0)
        glDeleteFramebuffers(1, [self.id])


    def attachTexture(self, attachment, texture):
        """ Attach a texture to the framebuffer at the given attachment """
        self.textures[attachment] = texture


    def finalize(self):
        """ Finalize the framebuffer construction """

        self.bind(GL_FRAMEBUFFER)

        for a, t in self.textures.iteritems():
            glFramebufferTexture(GL_DRAW_FRAMEBUFFER, a, t.id, 0)

        glDrawBuffer(GL_COLOR_ATTACHMENT0)

        status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
        if status != GL_FRAMEBUFFER_COMPLETE:
            print "Error: incomplete framebuffer (status: {})".format(status)
            return False

        return True


    def bind(self, target=GL_FRAMEBUFFER):
        """ Bind the framebuffer to the given target """
        if id != 0: glBindFramebuffer(target, self.id)
