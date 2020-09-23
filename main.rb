require 'gosu'
BASE_BALL_SPEED = 800
BALL_SIZE = 10 
BALL_COLOR = Gosu::Color::WHITE
TARGET_LINE_COLOR_1 = Gosu::Color::WHITE
TARGET_LINE_COLOR_2 = Gosu::Color::BLACK
BASE_LAUNCH_INTERVAL = 1/6.0
BALL_RETURN_TIME = 1
class GGTAN < Gosu::Window
    attr_accessor :balls, :blocks, :bbtan
    def initialize
        super 400, 600
        @balls = []
        @blocks = []
        @bbtan = BBTan.new width/2, height - 20
        @target_line_x = nil
        @target_line_y = nil

        @launch_speed_multiplier = 1

        #ready, firing, returning
        @game_state = :returning
        #launch
        @last_launch_stamp = nil
        @launch_progression = 0
        #go
        3.times{add_ball}
    end
    def add_ball
        @balls.push Ball.new self, balls.length, 0, @bbtan.y
    end
    def update
        dt = self.update_interval / 1000.0
        time = Time.now.to_f
        balls.each{|ball| ball.update dt, time}
        bbtan.update dt
        case @game_state
        when :ready
            
        when :firing
            @last_launch_stamp = time - BASE_LAUNCH_INTERVAL unless @last_launch_stamp
            if (@last_launch_stamp) + BASE_LAUNCH_INTERVAL / @launch_speed_multiplier <= time
                if ball = @balls[@launch_progression]
                    #TODO: allow for sub frame launches
                    ball.launch
                    @last_launch_stamp = time
                    @launch_progression+=1
                else
                    @game_state = :returning
                end
            end
        end
    end
    def draw
        @balls.each(&:draw)
        @bbtan.draw
        if button_down?(Gosu::MsLeft) && @game_state == :ready
            Gosu.draw_line @bbtan.x, @bbtan.y, TARGET_LINE_COLOR_1, mouse_x.clamp(0, width), mouse_y.clamp(0, height), TARGET_LINE_COLOR_2 
        end
    end
    def launch rad_angle
        return unless @game_state == :ready
        puts "launch! #{rad_angle}"
        
        scl = BASE_BALL_SPEED * @launch_speed_multiplier
        x_spd, y_spd = get_vect_from_angle(rad_angle ,scl, -scl)
        
        @balls.each{|ball| ball.arm x_spd, y_spd}
        
        @game_state = :firing
        @launch_progression = 0
    end
    def ball_ready ball
        puts "ball #{ball.id} is ready"
        @game_state = :ready unless @balls.reduce(false){|acc, ball| (ball.state != :ready) || acc}
        puts "game is ready" if @game_state == :ready
    end
    def needs_cursor?
        true
    end
    def mouse_move
        puts "wow"
    end
    def button_up id
        if id == Gosu::MsLeft
            launch get_angle_from_vect(mouse_x - @bbtan.x , -mouse_y + @bbtan.y)
        end
    end
end

class Ball
    # state
    # ready, armed, launched, returning
    attr_accessor :x, :y, :x_spd, :y_spd, :state
    attr_reader :id
    def initialize game, id, x, y, x_spd = 0, y_spd = 0, state = :returning
        @game, @id, @x, @y, @x_spd, @y_spd, @state = game, id, x+0.0, y+0.0, x_spd+0.0, y_spd+0.0, state
    end
    def update dt, time = nil
        case state
        when :launched
            @x+= @x_spd*dt
            @y+= @y_spd*dt
            check_collisions
        when :returning#, :ready
            @return_start = {time:time, x:@x, y:@y} unless @return_start
            progression = get_smooth_progression((time - @return_start[:time]) / BALL_RETURN_TIME, :ease)
            @x = (@game.bbtan.x - @return_start[:x])*progression + @return_start[:x]
            @y = (@game.bbtan.y - @return_start[:y])*progression + @return_start[:y]
            set_ready if time - @return_start[:time] >= BALL_RETURN_TIME
        end
    end
    def check_collisions
        @x_spd *= -1 if @x >= @game.width || @x <= 0
        @y_spd *= -1 if @y <= 0
        set_return if @y >= @game.bbtan.y
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
        @return_start = nil
        @state = :returning
    end
    def draw
        Gosu.draw_rect(x, y, BALL_SIZE, BALL_SIZE, BALL_COLOR)
    end
end

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

def get_rad deg
    deg * Math::PI / 180
end
def get_deg rad
    (rad / Math::PI) * 180
end
def get_angle_from_vect x, y
    puts "woo #{x}, #{y}"
    angle = Math.atan(y.abs/x.abs)
    if x<0
        return angle - Math::PI if y<0
        return Math::PI - angle
    end
    return -angle if y<0
    angle
end
def get_vect_from_angle rad, scl = 1, scl_y = nil
    return (Math.cos(rad) * scl), (Math.sin(rad)*(scl_y || scl))
end
def get_smooth_progression progression, timing_function= :ease
    return progression * progression * (3 - 2 * progression) if timing_function == :ease
    progression
end

GGTAN.new.show