require 'gosu'
require_relative '../utils.rb'
class TestIntersection < Gosu::Window
    def initialize
        super 500,500
        #segment1
        @x1 = 200
        @y1 = 300
        @x2 = 350
        @y2 = 250

        #segment2
        @x3 = 0
        @y3 = 0
        @x4 = 0
        @y4 = 0

        #rectangle 1
        @rx = 100
        @ry = 30
        @rw = 250
        @rh = 150
        
    end
    def button_down id
        @x3, @y3 = mouse_x, mouse_y if id == Gosu::MsLeft
    end
    def update
        @x4, @y4 = mouse_x, mouse_y if button_down? Gosu::MsLeft
    end
    def draw
        #draw
        color1 = Gosu::Color::WHITE
        color1 = Gosu::Color::GREEN if segments_intersect? @x1,@y1,@x2,@y2, @x3,@y3,@x4,@y4
        Gosu.draw_line(@x1,@y1,color1,@x2,@y2, color1)

        color2 = Gosu::Color::WHITE
        color2 = Gosu::Color::GREEN if rectangle_face_segment_intersection? :top, @rx,@ry,@rw,@rh, @x3,@y3,@x4,@y4
        color2 = Gosu::Color::RED if rectangle_face_segment_intersection? :left, @rx,@ry,@rw,@rh, @x3,@y3,@x4,@y4
        color2 = Gosu::Color::BLUE if rectangle_face_segment_intersection? :bottom, @rx,@ry,@rw,@rh, @x3,@y3,@x4,@y4
        color2 = Gosu::Color::YELLOW if rectangle_face_segment_intersection? :right, @rx,@ry,@rw,@rh, @x3,@y3,@x4,@y4
        Gosu.draw_rect(@rx,@ry,@rw,@rh,color2)

        Gosu.draw_line(@x3,@y3,Gosu::Color::WHITE,@x4,@y4, Gosu::Color::WHITE)
    end
    def needs_cursor?
        true
    end
end

TestIntersection.new.show