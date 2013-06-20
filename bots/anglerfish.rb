class Anglerfish < RTanque::Bot::Brain
  include RTanque::Bot::BrainHelper
  NAME = 'Anglerfish'
  AIM_TOLERANCE = RTanque::Heading::FULL_ANGLE*5

  def tick!
    @ticks = @ticks ? @ticks + 1 : 0
    ## main logic goes here
    
    # use self.sensors to detect things
    # See http://rubydoc.info/github/awilliams/RTanque/master/RTanque/Bot/Sensors
    
    # use self.command to control tank
    # See http://rubydoc.info/github/awilliams/RTanque/master/RTanque/Bot/Command
    
    # self.arena contains the dimensions of the arena
    # See http://rubydoc.info/github/awilliams/RTanque/master/frames/RTanque/Arena

    command.turret_heading = sensors.radar_heading
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
    if (target && target.name == @prev_name)
      target_location = projection(sensors.position, target.heading, target.distance)
      puts target_location
      target_heading = RTanque::Heading.new_between_points(@prev_location, target_location)
      target_speed = calc_dist(@prev_location, target_location)
      aim_point = projection(target_location, target_heading, target_speed)
      aim_heading = RTanque::Heading.new_between_points(sensors.position, aim_point)
      command.turret_heading = aim_heading
      command.radar_heading = aim_heading
      if (sensors.turret_heading - aim_heading < AIM_TOLERANCE)
        self.command.fire(MAX_FIRE_POWER)
      end
    elsif (target)
      command.radar_heading = target.heading
      command.turret_heading = sensors.turret_heading
      @prev_name = target.name
      @prev_location = projection(sensors.position, target.heading, target.distance)
    else
      command.turret_heading = sensors.turret_heading
      command.radar_heading = sensors.radar_heading + MAX_RADAR_ROTATION
    end

    command.speed = MAX_BOT_SPEED

    # ZigZag!
    if (sensors.position.on_wall?)
      # Replace command.heading with general_heading
      if (sensors.position.on_bottom_wall?)
        command.heading = RTanque::Heading.new(RTanque::Heading::NORTH)
      elsif (sensors.position.on_top_wall?)
        command.heading = RTanque::Heading.new(RTanque::Heading::SOUTH)
      elsif (sensors.position.on_right_wall?)
        command.heading = RTanque::Heading.new(RTanque::Heading::WEST)
      else
        command.heading = RTanque::Heading.new(RTanque::Heading::EAST)
      end
    else
      # replace sensors.heading with general_heading
      command.heading = sensors.heading + MAX_BOT_ROTATION*Math.cos(@ticks/20)
    end
  end

  def projection(from_point, heading, distance)
    projected_x = from_point.x + distance*Math.cos(heading)
    projected_y = from_point.y + distance*Math.sin(heading)

    projected_x = 0 if projected_x < 0
    projected_x = from_point.arena.width if projected_x > from_point.arena.width

    projected_y = 0 if projected_y < 0
    projected_y = from_point.arena.height if projected_x > from_point.arena.height

    return RTanque::Point.new(projected_x, projected_y, from_point.arena)
  end

  def calc_dist(from_point, to_point)
    delta_x = to_point.x - from_point.x
    delta_y = to_point.y - from_point.y
    return Math.sqrt(delta_x*delta_x + delta_y*delta_y)
  end
end
