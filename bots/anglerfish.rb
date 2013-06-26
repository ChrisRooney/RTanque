class Anglerfish < RTanque::Bot::Brain
  include RTanque::Bot::BrainHelper
  NAME = 'Anglerfish'
  AIM_TOLERANCE = RTanque::Heading::FULL_ANGLE*5
  ZIGZAG_AMPLITUDE = Math::PI/2

  def tick!
    @ticks = @ticks ? @ticks + 1 : 0
    
    @general_heading ||= RTanque::Heading.rand

    # ZigZag!
    zigzag = ZIGZAG_AMPLITUDE*Math.sin(@ticks/30)

    # Bounce!
    # Fix reflection to account for zigzag
    if (sensors.position.on_wall?)
      zigzag = 0
      if (sensors.position.on_bottom_wall? && @on_wall != 'bottom')
        @on_wall = 'bottom'
        @general_heading = reflect(@general_heading, RTanque::Heading::NORTH)
      elsif (sensors.position.on_top_wall? && @on_wall != 'top')
        @on_wall = 'top'
        @general_heading = reflect(@general_heading, RTanque::Heading::SOUTH)
      elsif (sensors.position.on_right_wall? && @on_wall != 'right')
        @on_wall = 'right'
        @general_heading = reflect(@general_heading, RTanque::Heading::WEST)
      elsif (sensors.position.on_left_wall? && @on_wall != 'left')
        @on_wall = 'left'
        @general_heading = reflect(@general_heading, RTanque::Heading::EAST)
      end
    else
      # Don't bounce again until heading has corrected
      @on_wall = nil
    end

    new_heading = @general_heading + zigzag

    # Don't zigzag when on a wall
    # if ((@general_heading - new_heading).abs > Math::PI/2)
    #   new_heading = @general_heading
    # end
    
    # puts "General #{@general_heading.to_degrees}, Exact #{new_heading.to_degrees}, Zigzag #{zigzag/Math::PI}"
    
    command.heading = new_heading

    my_next_location = projection(sensors.position, new_heading, sensors.speed)
    # puts "Current: (#{sensors.position.x}, #{sensors.position.y}), Projected: (#{my_next_location.x}, #{my_next_location.y})"
    # find target
    scan = sensors.radar
    # puts sensors.radar.first.inspect
    if (scan.count > 0)
      scan.sort_by {|bot| (bot.heading - sensors.turret_heading).to_f.abs}
      target = scan.first
      #puts "AH SEEN EM #{target.name}"
    else
      target = nil
    end
    #puts scan.count
    if (target)
      target_location = projection(sensors.position, target.heading, target.distance)
      if (target.name == @prev_name)
        #puts "old target #{target.heading.to_s}"
        # puts target_location
        target_heading = RTanque::Heading.new_between_points(@prev_location, target_location)
        target_speed = calc_dist(@prev_location, target_location)
        aim_point = projection(target_location, target_heading, target_speed)
        aim_heading = RTanque::Heading.new_between_points(my_next_location, aim_point)
        command.turret_heading = target.heading
        command.radar_heading = aim_heading
        if (aim_heading.delta(sensors.turret_heading).abs < AIM_TOLERANCE)
          self.command.fire(MAX_FIRE_POWER)
        end
      else
        #puts "new target #{target.heading.to_s}"
        next_target_heading = RTanque::Heading.new_between_points(my_next_location, target_location)
        # puts "Current: #{target.heading.to_degrees}, Projected: #{next_target_heading.to_degrees}"
        command.radar_heading = next_target_heading
        command.turret_heading = sensors.turret_heading
        @prev_name = target.name
        @prev_location = projection(sensors.position, target.heading, target.distance)
      end
    else
      @prev_name = nil
      @prev_location = nil
      #puts "no target"
      command.turret_heading = sensors.turret_heading
      command.radar_heading = sensors.radar_heading + MAX_RADAR_ROTATION
    end
    #puts "Radar #{sensors.radar_heading.to_s}"
    #puts "Turret #{sensors.turret_heading.to_s}"
    command.speed = MAX_BOT_SPEED
  end

  def projection(from_point, heading, distance)
    projected_x = (from_point.x + distance*Math.sin(heading)).round(10)
    projected_y = (from_point.y + distance*Math.cos(heading)).round(10)

    projected_x = 0 if projected_x < 0
    projected_x = from_point.arena.width if projected_x > from_point.arena.width

    projected_y = 0 if projected_y < 0
    projected_y = from_point.arena.height if projected_y > from_point.arena.height

    return RTanque::Point.new(projected_x, projected_y, from_point.arena)
  end

  def calc_dist(from_point, to_point)
    delta_x = to_point.x - from_point.x
    delta_y = to_point.y - from_point.y
    return Math.sqrt(delta_x*delta_x + delta_y*delta_y)
  end

  def reflect(heading, normal)
    incident = heading.delta(normal+Math::PI)
    reflection = normal + incident
    return RTanque::Heading.new(reflection)
  end
end
