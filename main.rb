require 'gosu'
BASE_FPS = 1000
BASE_BALL_SPEED = 800
BALL_SIZE = 10 
BALL_COLOR = Gosu::Color::WHITE
TARGET_LINE_COLOR_1 = Gosu::Color::WHITE
TARGET_LINE_COLOR_2 = Gosu::Color::BLACK
BASE_LAUNCH_INTERVAL = 1/6.0
BALL_RETURN_TIME = 1
MIN_DEG_ANGLE = 10
class GGTAN < Gosu::Window
    attr_accessor :balls, :blocks, :bbtan
    def initialize
        super 400, 600, {update_interval: 1000.0/BASE_FPS}
        @balls = []
        @blocks = []
        @bbtan = BBTan.new width/2, height - 20
        @target_line_x = nil
        @target_line_y = nil
        @fps_display_font = Gosu::Font.new(20)

        @launch_speed_multiplier = 1

        #ready, firing, returning
        @game_state = :returning
        #launch
        @last_launch_stamp = nil
        @launch_progression = 0
        #go
        10.times{add_ball}
    end
    def add_ball
        @balls.push Ball.new self, balls.length, 0, @bbtan.y
    end
    def update
        dt = self.update_interval / 1000.0
        @ups = 1/dt
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
        #fps
        @fps_display_font.draw_text("#{@ups.floor} ups", 5, 5, 1, 1, 1, Gosu::Color::WHITE)
        @fps_display_font.draw_text("#{Gosu.fps} fps", 5, 30, 1, 1, 1, Gosu::Color::WHITE)
    end
    def launch rad_angle
        return unless @game_state == :ready
        return unless rad_angle.between? get_rad(MIN_DEG_ANGLE), get_rad(180-MIN_DEG_ANGLE)
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
        @x_spd *= -1 if right >= @game.width || @x <= 0
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
        bottom, right = y + BALL_SIZE, x + BALL_SIZE
        Gosu.draw_rect(x, y, BALL_SIZE, BALL_SIZE, BALL_COLOR)
        #borders
        Gosu.draw_line x, y, Gosu::Color::GRAY, right, y , Gosu::Color::GRAY #top
        Gosu.draw_line x, y, Gosu::Color::GRAY, x, bottom , Gosu::Color::GRAY #left
        Gosu.draw_line x, bottom, Gosu::Color::GRAY, right , bottom, Gosu::Color::GRAY #bottom
        Gosu.draw_line right, y, Gosu::Color::GRAY, right , bottom , Gosu::Color::GRAY #right
    end
    def bottom
        y + BALL_SIZE
    end
    def right
        x + BALL_SIZE
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