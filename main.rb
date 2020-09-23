require 'gosu'
BALL_SPEED = 30
BALL_SIZE = 10
BALL_COLOR = Gosu::Color::WHITE
LAUNCH_INTERVAL = 1000/15
BALL_RETURN_TIME = 2
class GGTAN < Gosu::Window
    attr_accessor :balls, :blocks, :bbtan_x, :bbtan_y, :launch_x, :launch_y
    def initialize
        super 400, 600
        @balls = []
        @blocks = []
        @bbtan_x = width/2
        @bbtan_y = height - 20
        @launch_x = bbtan_x
        @launch_y = bbtan_y

        #launch
        @last_launch_stamp = nil

        #go
        add_ball
        launch get_rad 45
    end
    def add_ball
        balls.push Ball.new self, 0, height - 20
    end
    def update
        dt = 1.0/60.0
        time = Time.now
        balls.each{|ball| ball.update dt, time}
    end
    def draw
        @balls.each(&:draw)
    end
    def launch rad_angle
        x_spd = Math.cos(rad_angle) * BALL_SPEED
        y_spd = Math.sin(rad_angle) * BALL_SPEED
    end
    def needs_cursor?
        true
    end
end

class Ball
    # state
    # ready, armed, launched, returning
    attr_accessor :x, :y, :x_spd, :y_spd, :state
    def initialize game, x, y, x_spd = 0, y_spd = 0, state = :returning
        @game, @x, @y, @x_spd, @y_spd, @state = game, x+0.0, y+0.0, x_spd+0.0, y_spd+0.0, state
    end
    def update dt, time = nil
        case state
        when :launched
            x+= x_spd*dt
            y+= y_spd*dt
        when :returning
            @return_start = {time:time, x:@x, y:@y} unless @return_start
            progression = get_smooth_progression((time - @return_start[:time]) / BALL_RETURN_TIME, :ease)
            @x = (@game.bbtan_x - @return_start[:x])*progression + @return_start[:x]
            @y = (@game.bbtan_y - @return_start[:y])*progression + @return_start[:y]
            if time - @return_start[:time] >= BALL_RETURN_TIME
                @x, @y = @game.bbtan_x, @game.bbtan_y
                @state = :ready
            end
        end
    end
    def draw
        Gosu.draw_rect(x, y, BALL_SIZE, BALL_SIZE, BALL_COLOR)
    end
end
def get_rad deg
    deg * Math::PI / 180
end
def get_smooth_progression progression, timing_function= :ease
    if timing_function == :ease
        return progression * progression * (3 - 2 * progression)
    else
        return progression
    end
end

GGTAN.new.show