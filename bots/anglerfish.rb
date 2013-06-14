class Anglerfish < RTanque::Bot::Brain
  include RTanque::Bot::BrainHelper
  NAME = 'Anglerfish'
  MAX_SNYC_ROTATION = [MAX_TURRET_ROTATION, MAX_RADAR_ROTATION].max

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
    if (target)
      command.turret_heading = target.heading
      self.command.fire(MAX_FIRE_POWER)
    else
      command.radar_heading = sensors.radar_heading + MAX_SNYC_ROTATION
    end

    command.speed = MAX_BOT_SPEED

    # ZigZag!
    if (sensors.position.on_wall?)
      if (sensors.position.on_bottom_wall?)
        puts "go north"
        command.heading = RTanque::Heading.new(RTanque::Heading::NORTH)
      elsif (sensors.position.on_top_wall?)
        puts "go south"
        command.heading = RTanque::Heading.new(RTanque::Heading::SOUTH)
      elsif (sensors.position.on_right_wall?)
        puts "go east"
        command.heading = RTanque::Heading.new(RTanque::Heading::WEST)
      else
        puts "go west"
        command.heading = RTanque::Heading.new(RTanque::Heading::EAST)
      end
      puts sensors.heading.to_degrees
    else
      puts "zigzag"
      command.heading = sensors.heading + MAX_BOT_ROTATION*Math.cos(@ticks/50)
    end
    #puts sensors.heading.inspect
  end
end
