import os.path, time, re
from utils import enum, hms

try:
    from OpenGL.GL import *
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"


SHADER_STAGE = enum('VERTEX', 'FRAGMENT')

def GetGLStage(estage):
    """ Get the OpenGL shader stage enum from a SHADER_STAGE enum value """
    stage = None
    if estage == SHADER_STAGE.VERTEX:
        stage = GL_VERTEX_SHADER
    elif estage == SHADER_STAGE.FRAGMENT:
        stage = GL_FRAGMENT_SHADER
    return stage

class ShaderDependency(object):

    def __init__(self, filename, timestamp):
        self.filename = filename
        self.timestamp = timestamp

    def checkNewer(self):
        timestamp = time.ctime(os.path.getmtime(self.filename))
        return timestamp > self.timestamp


def readShaderFile(filename):
    """ Read a shader file and return it along with its dependencies """

    def _readShaderFile(filename, deps):
        source = ""
        with open(filename) as f:
            for line in f.readlines():
                if line.startswith('#include '):
                    beg = line.find('"')
                    end = line.find('"', beg+1)
                    inc = line[beg+1:end]
                    dirname = os.path.dirname(filename)
                    include = os.path.normpath(os.path.join(dirname, inc))
                    if include not in deps:
                        deps.append(include)
                        src = _readShaderFile(include, deps)
                        source += '\n// >>>>> #include "{}"\n\n'.format(inc)
                        source += src
                        source += '\n// <<<<< #include "{}"\n'.format(inc)
                else:
                    source += line
        return source

    dependencies = []
    source = _readShaderFile(filename, dependencies)
    return source, dependencies



class Shader(object):
    """ OpenGL shader object """

    def __init__(self, stage):
        self.id = 0
        self.stage = stage
        self.source = None
        self.timestamp = None
        self.filename = None
        self.compiled = False
        self.dependencies = []


    def loadFromFile(self, filename):
        """ Load a shader for file """

        # Get the OpenGL stage enum value
        stage = GetGLStage(self.stage)
        if stage is None:
            print "Unknown shader stage: {}".format(self.stage)
            return False

        if self.id != 0:
            glDeleteShader(self.id)
            self.compiled = False

        # Create shader
        self.id = glCreateShader(stage)

        if self.id == 0:
            print "Failed to create {} shader".format(SHADER_STAGE.name(self.stage).lower())

        # Read shader source from file
        source, deps = readShaderFile(filename)

        # Add shader dependencies
        self.dependencies = []
        for dep in deps:
            timestamp = time.ctime(os.path.getmtime(dep))
            self.dependencies.append(ShaderDependency(dep, timestamp))

        # Get file information (filename and timestamp)
        self.filename = filename
        self.timestamp = time.ctime(os.path.getmtime(filename))

        if source == "":
            print "No source found in file '{}'".format(filename)
            return False

        # Set source and compile
        self.setSource(source)
        self.compile()

        return True


    def setSource(self, source):
        """ Set the shader source """
        self.source = source
        glShaderSource(self.id, source)


    def compile(self):
        """ Compile shader and check log for errors """
        glCompileShader(self.id)
        log = glGetShaderInfoLog(self.id)
        if log != "":
            print >> sys.stderr, "Shader source: {}".format(self.source)
            print >> sys.stderr, "Shader log: {}".format(log)
            with open("err.glsl", 'w') as f:
                f.write(self.source)
            self.compiled = False
        else:
            self.compiled = True
        return self.compiled


    def reloadIfNewer(self):
        """ Reload the shader if a new version is found """

        timestamp = time.ctime(os.path.getmtime(self.filename))
        # TODO: add rollback in case of reloading failure
        if timestamp > self.timestamp:
            print "[{}] - New version of '{}' detected. Reloading...".format(hms(), self.filename)
            self.loadFromFile(self.filename)
            return True
        else:
            for dep in self.dependencies:
                if dep.checkNewer():
                    print "[{}] - New version of dependency '{}' detected. Reloading '{}'...".format(hms(), dep.filename, self.filename)
                    self.loadFromFile(self.filename)
                    return True
        return False
