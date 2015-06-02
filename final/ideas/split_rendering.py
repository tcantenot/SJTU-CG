

class SplitRendering:

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


