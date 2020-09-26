class BBTan
    BBTAN_SIZE = 20
    BBTAN_COLOR = Gosu::Color::BLUE
    attr_reader :x, :y
    def initialize x, y
        @x, @y, @vir_x, @vir_y = x,y,x,y
    end
    def update dt

    end
    def draw
        Gosu.draw_rect(@vir_x, @vir_y - BBTAN_SIZE, BBTAN_SIZE / 2, BBTAN_SIZE, BBTAN_COLOR)
    end
    def y= y
        @y = y
        @vir_y = y
    end
end