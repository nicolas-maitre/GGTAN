class Ball
    BALL_RETURN_TIME = 1
    BALL_DEBUG_FONT = Gosu::Font.new(20)
    # state
    # ready, armed, launched, returning
    attr_accessor :x, :y, :x_spd, :y_spd, :state
    attr_reader :id
    def initialize game, id, x, y, x_spd = 0, y_spd = 0, state = :returning
        @game, @id, @x, @y, @x_spd, @y_spd, @state = game, id, x+0.0, y+0.0, x_spd+0.0, y_spd+0.0, state
        set_return if state==:returning
    end
    def update dt, time
        case state
        when :launched
            @next_x = @x + @x_spd * dt
            @next_y = @y + @y_spd * dt
            @x, @y = check_collisions @next_x, @next_y
        end
    end
    def check_collisions next_x, next_y
        next_right = next_x + BALL_SIZE
        next_bottom = next_y + BALL_SIZE

        #blocks
        @block_x, @block_y = @game.block_virtual_positions(next_x, next_y)
        if @game.block_touched? @block_x, @block_y
            puts "block touched #{@block_x}, #{@block_y}"
            
        end

        #walls
        handle_collision(:right, @game.width) if next_right >= @game.width
        handle_collision(:left, @game.x) if next_x <= @game.x
        handle_collision(:top, @game.y) if next_y <= @game.y
        set_return if next_y >= @game.bbtan.y

        return next_x,next_y
    end
    def handle_collision direction, coll_pos
        case direction
            when :left
                @x_spd = @x_spd.abs
            when :right
                @x_spd = - @x_spd.abs
            when :top
                @y_spd = @y_spd.abs
            when :bottom
                @y_spd = - @y_spd.abs
        end
    end
    
    def arm x_spd, y_spd
        @state = :armed
        @x_spd, @y_spd = x_spd, y_spd
    end
    def launch
        puts "launch ball #{@id}"
        @state = :launched
    end
    def set_ready
        @state = :ready
        @x, @y = @game.bbtan.x, @game.bbtan.y
        @game.ball_ready self
    end
    def set_return
        @state = :returning
        from_x, from_y = @x, @y
        @game.animate(BALL_RETURN_TIME) do |progression|
            smh_progression = smooth_progression(progression)
            @x = (@game.bbtan.x - from_x)*smh_progression + from_x
            @y = (@game.bbtan.y - from_y)*smh_progression + from_y
            set_ready if progression == 1
        end
    end
    def draw
        bottom, right = y + BALL_SIZE, x + BALL_SIZE
        Gosu.draw_rect(x, y, BALL_SIZE, BALL_SIZE, BALL_COLOR)
        #borders
        Gosu.draw_line x, y, Gosu::Color::GRAY, right, y , Gosu::Color::GRAY #top
        Gosu.draw_line x, y, Gosu::Color::GRAY, x, bottom , Gosu::Color::GRAY #left
        Gosu.draw_line x, bottom, Gosu::Color::GRAY, right , bottom, Gosu::Color::GRAY #bottom
        Gosu.draw_line right, y, Gosu::Color::GRAY, right , bottom , Gosu::Color::GRAY #right
        #debug
        draw_centered_text(BALL_DEBUG_FONT, "#{@next_x.floor}, #{@next_y.floor}", self.x, self.bottom + 5, BALL_SIZE, BALL_SIZE, Gosu::Color::GREEN) if @next_x && @next_y
        draw_centered_text(BALL_DEBUG_FONT, "#{@block_x}, #{@block_y}", self.x, self.bottom + 30, BALL_SIZE, BALL_SIZE, Gosu::Color::GREEN) if @block_x && @block_y
    end
    def bottom
        y + BALL_SIZE
    end
    def right
        x + BALL_SIZE
    end
end