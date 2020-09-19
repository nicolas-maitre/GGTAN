require 'gosu'
BALL_SPEED = 5
LAUNCH_INTERVAL = 1000/15
class GGTAN < Gosu::Window
    def initialize
        super 400, 600
        @balls = []
        @blocks = []

        #launch
        @last_launch_stamp = nil

        #go
        launch 
    end
    def add_ball

    end
    def update

    end
    def draw

    end
    def launch rad_angle
        x_spd = Math.cos(rad_angle) * BALL_SPEED
        y_spd = Math.sin(rad_angle) * BALL_SPEED

        #sin(a) = opp/hyp
        #opp = sin(a) * hyp
    end
    def needs_cursor?
        true
    end
end
GGTAN.new.show

class Ball
    attr_accessor :x, :y, :x_spd, :y_spd
    def initialize x, y, x_spd, y_spd
        @x, @y, @x_spd, @y_spd = x, y, x_spd, y_spd
    end
    def update dt
        x+= x_spd
        y+= y_spd
    end
    def draw
        
    end
end