class Ball
    DEBUG_BALL_TRAJECTORY = true
    BALL_RETURN_TIME = 1
    RECT_DIRECTION_FACE = {
        top: :bottom,
        left: :right,
        bottom: :top,
        right: :left,
    }
    HALF_SIZE = BALL_SIZE / 2
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
            @x, @y = @x.clamp(@game.x, @game.width), @y.clamp(@game.y, @game.height) #prevent ball runaway, height and width are incorrect
            next_x = @x + @x_spd * dt
            next_y = @y + @y_spd * dt
            @debug_old_pos = {x:@x, y: @y}
            @debug_next_pos = {x: next_x, y: next_y}
            check_collisions next_x, next_y
            check_bonus
        end
    end
    def check_collisions next_x, next_y
        base_x, base_y = @x, @y

        next_right = next_x + BALL_SIZE
        next_bottom = next_y + BALL_SIZE

        #blocks
        center_block_col, center_block_line = @game.block_virtual_positions(next_x, next_y)
        @debug_block_center_v_pos = {x: center_block_col, y: center_block_line}
        blocks_to_check = ((-1..1).map{|b_col_off| (-1..1).map{|b_line_off| [center_block_col + b_col_off, center_block_line + b_line_off]}}).flatten
        blocks_to_check.unshift [center_block_col, center_block_line] #TODO: optimise pls
        @debug_blocks_v_pos = blocks_to_check
        for block_v_pos in blocks_to_check
            block_col, block_line = block_v_pos
            if @game.block_touched?(block_col, block_line)
                block_x, block_y = @game.block_real_positions(block_col, block_line)
                block_center_x, block_center_y = block_x + BLOCK_SIZE / 2, block_y + BLOCK_SIZE / 2
                puts "block that may be touched: #{block_col}, #{block_line} | #{block_x}, #{block_y}"
                
                directions_to_test = []

                # directions_to_test << :right if @x_spd > 0
                # directions_to_test << :left if @x_spd < 0
                # directions_to_test << :bottom if @y_spd > 0
                # directions_to_test << :top if @y_spd < 0

                directions_to_test << :right if @x_spd > 0 || @x < block_center_x
                directions_to_test << :left if @x_spd < 0 || @x > block_center_x
                directions_to_test << :bottom if @y_spd > 0 || @y < block_center_y
                directions_to_test << :top if @y_spd < 0 || @y > block_center_y

                # directions_to_test << :right if @x < block_center_x
                # directions_to_test << :left if @x > block_center_x
                # directions_to_test << :bottom if @y < block_center_y
                # directions_to_test << :top if @y > block_center_y
                
                did_find_collision = false
                for direction in directions_to_test
                    #TODO: improve the test vector
                    if rectangle_face_segment_intersection?(RECT_DIRECTION_FACE[direction], block_x,block_y,BLOCK_SIZE,BLOCK_SIZE, @x + HALF_SIZE, @y + HALF_SIZE, next_x + HALF_SIZE, next_y + HALF_SIZE)
                        puts "block bounce on face #{RECT_DIRECTION_FACE[direction]}"
                        handle_block_bounce(direction, block_x, block_y, next_x, next_y)
                        @game.block_touched(block_col, block_line) unless did_find_collision
                        did_find_collision = true
                    end
                end
                # unless did_find_collision
                #     for direction in directions_to_test
                #         puts "bounce assumed on face #{RECT_DIRECTION_FACE[direction]}"
                #         handle_block_bounce direction, block_x, block_y, next_x, next_y
                #     end
                # end
                # @game.block_touched(block_col, block_line)

                # if did_find_collision
                #     puts "wow great job"
                #     # break
                # end
            end
        end

        #walls
        handle_bounce(:right, @game.width, next_x) if next_right >= @game.width
        handle_bounce(:left, @game.x, next_x) if next_x <= @game.x
        handle_bounce(:top, @game.y, next_y) if next_y <= @game.y
        set_return if next_y >= @game.bbtan.y

        @x, @y = next_x,next_y if (@x == base_x && @y == base_y)
        # @x, @y = next_x,next_y
    end
    def check_bonus
        v_pos_x, v_pos_y = @game.block_virtual_positions(@x, @y)
        return unless @game.bonus_touched?(v_pos_x, v_pos_y)
        bonus_touched = @game.bonus_at(v_pos_x, v_pos_y)
        case bonus_touched
        when :+
            @game.clear_bonus v_pos_x, v_pos_y
            @game.add_ball
        end
    end
    def handle_block_bounce(direction, block_x, block_y, next_x, next_y)
        coll_pos, next_pos = block_x, next_x if direction == :right
        coll_pos, next_pos = (block_x + BLOCK_SIZE),next_x if direction == :left
        coll_pos, next_pos = block_y, next_y if direction == :bottom
        coll_pos, next_pos = (block_y + BLOCK_SIZE), next_y if direction == :top
        handle_bounce direction, coll_pos, next_pos
    end
    def handle_bounce direction, coll_pos, next_pos
        case direction
        when :left, :right
            # puts "handle horizontal bounce dir:#{direction}, coll_pos:#{coll_pos.floor 1}, x:#{@x.floor 1}, next_x:#{next_pos.floor 1}"
            @x = linear_bouce_pos(@x, coll_pos, next_pos)
            @x_spd *= -1
            # puts "resulting x:#{@x.floor 1}"
        when :top, :bottom
            @y = linear_bouce_pos(@y, coll_pos, next_pos)
            @y_spd *= -1
        end
    end
    def linear_bouce_pos pos, coll_pos, next_pos
        first_move = coll_pos - pos
        res = -first_move + next_pos
        return res
        # first_move = (pos + coll_spd + coll_pos)
        # return (pos + coll_spd + coll_pos), -coll_spd
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
        return unless DEBUG_BALL_TRAJECTORY
        draw_centered_text(DEBUG_FONT, "#{@x.floor}, #{@y.floor}", self.x, self.bottom + 5, BALL_SIZE, BALL_SIZE, Gosu::Color::GREEN)
        if @debug_next_pos && @debug_old_pos && @debug_blocks_v_pos && @debug_block_center_v_pos
            Gosu.draw_rect(@debug_next_pos[:x], @debug_next_pos[:y], BALL_SIZE, BALL_SIZE, Gosu::Color::YELLOW)
            Gosu.draw_rect(@debug_old_pos[:x], @debug_old_pos[:y], BALL_SIZE, BALL_SIZE, Gosu::Color::GRAY)
            Gosu.draw_line(@debug_old_pos[:x] + HALF_SIZE, @debug_old_pos[:y] + HALF_SIZE, Gosu::Color::YELLOW, @debug_next_pos[:x] + HALF_SIZE , @debug_next_pos[:y] + HALF_SIZE , Gosu::Color::YELLOW)
            c_rct_real_pos_x, c_rct_real_pos_y = @game.block_real_positions(@debug_block_center_v_pos[:x], @debug_block_center_v_pos[:y])
            Gosu.draw_rect(c_rct_real_pos_x, c_rct_real_pos_y, BLOCK_SIZE, BLOCK_SIZE, Gosu::Color::rgba(128,128,128,128))
            # for rect_v_pos in @debug_blocks_v_pos
            #     # pp rect_v_pos
            #     rect_real_pos_x, rect_real_pos_y = @game.block_real_positions(rect_v_pos[0], rect_v_pos[1])
            #     Gosu.draw_rect(rect_real_pos_x, rect_real_pos_y, BLOCK_SIZE, BLOCK_SIZE, Gosu::Color::rgba(128,128,128,128))
            # end
            draw_centered_text(DEBUG_FONT, "#{@debug_next_pos[:x].floor}, #{@debug_next_pos[:y].floor} | #{@debug_block_center_v_pos[:x]}, #{@debug_block_center_v_pos[:y]}", self.x, self.bottom + 30, BALL_SIZE, BALL_SIZE, Gosu::Color::GREEN)
        end
    end
    def bottom
        y + BALL_SIZE
    end
    def right
        x + BALL_SIZE
    end
end