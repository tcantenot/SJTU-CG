import os.path, time
from utils import enum

try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"


SHADER_STAGE = enum('VERTEX', 'FRAGMENT')

def GetGLStage(estage):
    stage = None

    if estage == SHADER_STAGE.VERTEX:
        stage = GL_VERTEX_SHADER

    elif estage == SHADER_STAGE.FRAGMENT:
        stage = GL_FRAGMENT_SHADER

    return stage


class Shader(object):

    def __init__(self, stage):
        self.id = 0
        self.stage = stage
        self.timestamp = None
        self.filename = None
        self.compiled = False

    def loadFromFile(self, filename):
        stage = GetGLStage(self.stage)
        if stage is None:
            print "Unknown shader stage: {}".format(self.stage)
            return False

        self.id = glCreateShader(stage)

        if self.id == 0:
            print "Failed to create {} shader".format(SHADER_STAGE.name(self.stage).lower())

        source = None
        with open(filename) as f:
            source = "".join(f.readlines())

        self.timestamp = time.ctime(os.path.getmtime(filename))
        self.filename = filename

        if source == "":
            print "No source found in file '{}'".format(filename)
            return False

        glShaderSource(self.id, source)
        glCompileShader(self.id)

        self.compiled = True

        return True


    def reloadIfNewer(self):
        timestamp = time.ctime(os.path.getmtime(self.filename))
        # TODO: add rollback in case of reloading failure
        if timestamp > self.timestamp:
            print "New version of '{}' detected".format(self.filename)
            print "Reloading..."
            self.loadFromFile(self.filename)
            return True
        return False
