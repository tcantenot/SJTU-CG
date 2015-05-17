from vec3 import *

class Camera(object):

    def __init__(self):
        self.pos = Vec3(0, 0, 0)

    def translate(self, t):
        self.pos += t
