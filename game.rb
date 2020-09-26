require 'gosu'
require_relative 'utils'
require_relative 'ball'
require_relative 'bbtan'

BASE_BALL_COUNT = 1
BASE_BALL_SPEED = 300
BALL_SIZE = 10 
BALL_COLOR = Gosu::Color::WHITE
TARGET_LINE_COLOR_1 = Gosu::Color::WHITE
TARGET_LINE_COLOR_2 = Gosu::Color::BLACK
BASE_LAUNCH_INTERVAL = 1/6.0
BALL_RETURN_TIME = 1
MIN_DEG_ANGLE = 10

GRID_HEIGHT = 10
GRID_WIDTH = 6
BLOCK_SIZE = 50
BLOCK_SPACING = 5
BLOCK_FONT = Gosu::Font.new(40)

DEBUG_FONT = Gosu::Font.new(20)

TOP_MENU_HEIGHT = BLOCK_SIZE
PLATFORM_HEIGHT = BLOCK_SIZE
class GGTAN < Gosu::Window
    attr_accessor :balls, :blocks, :bbtan
    def initialize
        window_width = (BLOCK_SIZE + BLOCK_SPACING) * GRID_WIDTH + BLOCK_SPACING
        window_height = TOP_MENU_HEIGHT + (BLOCK_SIZE + BLOCK_SPACING) * GRID_HEIGHT + PLATFORM_HEIGHT
        super window_width, window_height
        puts self.x, self.y, self.width, self.height
        @animations = []
        @balls = []
        @block_lines = []
        @bbtan = BBTan.new width/2, height - PLATFORM_HEIGHT
        @target_line_x = nil
        @target_line_y = nil
        
        @grid_top_offset = 0
        @launch_speed_multiplier = 1
        
        @level = 0
        #transitionning, ready, firing, returning, end
        @game_state = :returning
        #launch
        
        @last_launch_stamp = nil
        @launch_progression = 0
        #go
        BASE_BALL_COUNT.times{add_ball}
    end
    def next_level
        @game_state = :transitionning
        @level+=1
        add_line do
            @game_state = :ready
            unless((@block_lines[GRID_HEIGHT - 1] || []).sum == 0)
                #blocks present in last line
                end_game :lost
            end
        end
    end
    def add_ball
        @balls.push Ball.new self, balls.length, 0, @bbtan.y
    end
    def add_line &done_handler
        @block_lines.unshift(Array.new(GRID_WIDTH).fill(@level)) #temp generation
        pp @block_lines
        animate(1) do |progression|
            @grid_top_offset = (BLOCK_SIZE + BLOCK_SPACING)*(1-(smooth_progression progression))
            next if progression < 1
            #animation finished
            done_handler.call if done_handler
        end
    end
    def update
        #time
        time = Time.now.to_f
        dt = @last_update_stamp ? (time - @last_update_stamp) : 0
        @last_update_stamp = time
        @ups = 1.0/dt if dt > 0
        #updates
        update_animations time
        balls.each{|ball| ball.update dt, time}
        bbtan.update dt
        case @game_state  
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
        #top menu
        Gosu.draw_rect(0,0,self.width, TOP_MENU_HEIGHT, Gosu::Color::BLUE)
        #grid
        Gosu.clip_to self.x, self.y, self.width, (self.height - TOP_MENU_HEIGHT - self.y) do
            draw_grid
        end
        #balls
        @balls.each(&:draw)
        @bbtan.draw
        if button_down?(Gosu::MsLeft) && @game_state == :ready
            Gosu.draw_line @bbtan.x + (BALL_SIZE / 2), @bbtan.y + (BALL_SIZE / 2), TARGET_LINE_COLOR_1, mouse_x.clamp(0, width) + (BALL_SIZE / 2), mouse_y.clamp(0, height) + (BALL_SIZE / 2), TARGET_LINE_COLOR_2 
        end
        #fps
        DEBUG_FONT.draw_text("#{@ups.round} ups", 5, 5, 1, 1, 1, Gosu::Color::WHITE) if @ups
        fps_text = "#{Gosu.fps} fps"
        DEBUG_FONT.draw_text(fps_text, right - 5 - DEBUG_FONT.text_width(fps_text, 1), 5, 1, 1, 1, Gosu::Color::WHITE)
        #debug
        coord_x, coord_y = block_virtual_positions self.mouse_x, self.mouse_y
        r_coord_x, r_coord_y = block_real_positions coord_x, coord_y
        DEBUG_FONT.draw_text("#{coord_x}, #{coord_y}", 5, bottom - 30, 1, 1, 1, Gosu::Color::GREEN)
        r_coord_text = "#{r_coord_x}, #{r_coord_y}"
        DEBUG_FONT.draw_text(r_coord_text, DEBUG_FONT.text_width(r_coord_text, 1), bottom-30, 1, 1, 1, Gosu::Color::GREEN)
    end
    def draw_grid
        top_offset = self.y - @grid_top_offset + BLOCK_SPACING
        left_offset = self.x + BLOCK_SPACING
        @block_lines.each_with_index do |line, ind_line|
            line.each_with_index do |block_value, ind_col|
                block_x = left_offset + ind_col * (BLOCK_SIZE + BLOCK_SPACING)
                block_y = top_offset + ind_line * (BLOCK_SIZE + BLOCK_SPACING)
                if block_value > 0
                    Gosu.draw_rect(block_x, block_y, BLOCK_SIZE, BLOCK_SIZE, Gosu::Color::GRAY)
                    draw_centered_text(BLOCK_FONT, block_value, block_x, block_y, BLOCK_SIZE, BLOCK_SIZE, Gosu::Color::WHITE)
                end
            end
        end
        # Gosu.draw_rect(self.x, TOP_MENU_HEIGHT - @grid_top_offset, self.width, BLOCK_SIZE, Gosu::Color::RED)
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
        unless @balls.reduce(false){|acc, ball| (ball.state != :ready) || acc}
            puts "balls are ready"
            #all balls ready
            next_level
        end
    end
    def block_real_positions col, line
        x = self.x + BLOCK_SPACING + col * (BLOCK_SIZE + BLOCK_SPACING)
        y = self.y + BLOCK_SPACING + line * (BLOCK_SIZE + BLOCK_SPACING)
        return x, y
    end
    def block_virtual_positions x, y
        col = ((x - self.x - BLOCK_SPACING) / (BLOCK_SIZE + BLOCK_SPACING)).floor
        line = ((y - self.y - BLOCK_SPACING) / (BLOCK_SIZE + BLOCK_SPACING)).floor
        return col, line
    end
    def block_touched? col_ind, line_ind
        return false unless line = @block_lines[line_ind]
        return false unless val = line[col_ind]
        return false unless val > 0
        true
    end
    def block_touched col_ind, line_ind
        @block_lines[line_ind][col_ind] -= 1
    end
    def end_game status
        @game_state = :end
        puts "YOU LOST HAHA" if status == :lost
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
    def x
        0
    end
    def y
        TOP_MENU_HEIGHT
    end
    def bottom
        height
    end
    def right
        width
    end
    def animate duration, time = Time.now.to_f, &handler
        raise "no animation handler specified" unless handler
        @animations << {
            start_stamp: time,
            duration: duration,
            handler: handler
        }
    end
    def update_animations time
        ended_animations = []
        for animation in @animations.each
            progression = ((time - animation[:start_stamp]) / animation[:duration]).clamp(0,1)
            animation[:handler].call progression
            ended_animations << animation if progression == 1
        end
        @animations-=ended_animations unless ended_animations.empty?
    end
end

GGTAN.new.show