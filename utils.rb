def get_rad deg
    deg * Math::PI / 180
end
def get_deg rad
    (rad / Math::PI) * 180
end
def get_angle_from_vect x, y
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
def segments_intersect? ax, ay, bx, by, cx, cy, dx, dy
    #stolen and adapted from https://stackoverflow.com/a/9997374
    def ccw(x1, y1, x2, y2, x3, y3)
        return (y3-y1) * (x2-x1) > (y2-y1) * (x3-x1)
    end
    ccw(ax, ay, cx, cy, dx, dy) != ccw(bx, by, cx, cy, dx, dy) && ccw(ax, ay, bx, by, cx, cy) != ccw(ax, ay, bx, by, dx, dy)
end
def rectangle_face_segment_intersection? face, rx, ry, rw, rh, sx1, sy1, sx2, sy2
    rsx1, rsy1, rsx2, rsy2 = nil,nil,nil,nil
    case face
    when :top
        rsx1, rsy1, rsx2, rsy2 = rx, ry, rx+rw, ry
    when :left
        rsx1, rsy1, rsx2, rsy2 = rx, ry, rx, ry + rh
    when :bottom
        rsx1, rsy1, rsx2, rsy2 = rx, ry+rh, rx+rw, ry+rh
    when :right
        rsx1, rsy1, rsx2, rsy2 = rx+rw, ry, rx+rw, ry+rh
    end
    segments_intersect?(rsx1, rsy1, rsx2, rsy2, sx1, sy1, sx2, sy2)
end
def smooth_progression progression, timing_function= :ease
    return progression * progression * (3 - 2 * progression) if timing_function == :ease
    progression
end
def draw_centered_text(font, string, x, y, width, height, color)
    text_width = font.text_width(string, 1)
    font.draw_text(string, x + (width - text_width) / 2, y + ((height - font.height) / 2), 1, 1, 1, color)
end