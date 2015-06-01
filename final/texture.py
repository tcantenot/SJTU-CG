try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"

try:
    import numpy as np
except ImportError:
    raise ImportError, "Required dependency Numpy not present"

try:
    import Image
except ImportError:
    raise ImportError, "Required dependency Image not present"

import ctypes


class Texture(object):

    def __init__(self):
        self.id = 0
        self.size = (0, 0)
        self.format = None

    def create(self, size, internalFormat=GL_RGB, format=GL_RGB):
        self.destroy()
        self.size = size
        self.internalFormat = internalFormat;
        self.format = format;
        self.id = glGenTextures(1)
        glPixelStorei(GL_UNPACK_ALIGNMENT,1)
        glBindTexture(GL_TEXTURE_2D, self.id)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexImage2D(GL_TEXTURE_2D, 0, self.internalFormat, size[0], size[1], 0,
            self.format, GL_UNSIGNED_BYTE, ctypes.c_void_p(0))

    def bind(self):
        if self.id != 0: glBindTexture(GL_TEXTURE_2D, self.id)

    def resize(self, size, internalFormat=GL_RGB, format=GL_RGB):
        if self.id != 0:
            self.size = size
            self.bind()
            glTexImage2D(GL_TEXTURE_2D, 0, self.internalFormat, size[0], size[1], 0,
                self.format, GL_UNSIGNED_BYTE, ctypes.c_void_p(0))
            return False
        else:
            self.create(size, internalFormat, format)
            return True


    def destroy(self):
        if self.id != 0: glDeleteTextures([self.id])


    def loadFromFile(self, filename):

        self.destroy()

        img = Image.open(filename)

        if img is None: return False

        img_data = np.array(list(img.getdata()), np.uint8)

        self.id = glGenTextures(1)
        glPixelStorei(GL_UNPACK_ALIGNMENT,1)
        glBindTexture(GL_TEXTURE_2D, self.id)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, img.size[0], img.size[1], 0,
            GL_RGB, GL_UNSIGNED_BYTE, img_data)

        self.size = [d for d in img.size]

        return True
