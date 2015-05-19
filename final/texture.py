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


class Texture(object):

    def __init__(self):
        self.id = 0
        self.size = (0, 0)

    def loadFromFile(self, filename):

        if self.id != 0:
            glDeleteTextures(1, self.id)

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
